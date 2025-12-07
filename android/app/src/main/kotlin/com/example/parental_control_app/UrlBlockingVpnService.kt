package com.example.parental_control_app

import android.content.Intent
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.DatagramChannel
import java.util.concurrent.atomic.AtomicBoolean

class UrlBlockingVpnService : VpnService() {
    
    companion object {
        private const val TAG = "UrlBlockingVpnService"
        private var vpnInterface: ParcelFileDescriptor? = null
        private val isRunning = AtomicBoolean(false)
        private val blockedDomains = mutableSetOf<String>()
        var visitedUrlCallback: ((String) -> Unit)? = null
        
        fun addBlockedDomain(domain: String) {
            blockedDomains.add(domain.lowercase())
            Log.d(TAG, "Added blocked domain: $domain")
        }
        
        fun removeBlockedDomain(domain: String) {
            blockedDomains.remove(domain.lowercase())
            Log.d(TAG, "Removed blocked domain: $domain")
        }
        
        fun isDomainBlocked(domain: String): Boolean {
            return blockedDomains.contains(domain.lowercase())
        }
        
        fun getBlockedDomains(): Set<String> {
            return blockedDomains.toSet()
        }
        
        fun clearBlockedDomains() {
            blockedDomains.clear()
            Log.d(TAG, "Cleared all blocked domains")
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "VPN Service started")
        if (!isRunning.get()) {
            val ok = startVpn()
            Log.d(TAG, "startVpn invoked from onStartCommand -> $ok")
        }
        return START_STICKY
    }
    
    override fun onRevoke() {
        super.onRevoke()
        Log.d(TAG, "VPN Service revoked")
        stopVpn()
        val prefs = getSharedPreferences("content_control_prefs", Context.MODE_PRIVATE)
        val shouldRestart = prefs.getBoolean("tracking_enabled", false)
        if (shouldRestart) {
            Log.d(TAG, "Revoke received but tracking enabled; restarting service")
            val intent = Intent(this, UrlBlockingVpnService::class.java)
            // startForegroundService() is only available on API 26+ (Android 8.0+)
            // Use startService() as fallback for older versions
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }
    
    fun startVpn(): Boolean {
        if (isRunning.get()) {
            Log.d(TAG, "VPN already running")
            return true
        }
        try {
            startAsForeground()
            val builder = Builder()
                .setSession("Content Control VPN")
                .addAddress("10.0.0.2", 32)
                .addDnsServer("8.8.8.8")
                .addDnsServer("8.8.4.4")
                .addRoute("0.0.0.0", 0)
            vpnInterface = builder.establish()
            
            if (vpnInterface != null) {
                isRunning.set(true)
                Log.d(TAG, "VPN interface established")
                startPacketFiltering()
                return true
            } else {
                Log.e(TAG, "Failed to establish VPN interface")
                return false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting VPN: ${e.message}")
            return false
        }
    }
    
    private fun startAsForeground() {
        val channelId = "content_control_monitor"
        val channelName = "Content Control Monitoring"
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (nm.getNotificationChannel(channelId) == null) {
                nm.createNotificationChannel(
                    NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
                )
            }
        }
        val intent = Intent(this, MainActivity::class.java)
        val pi = PendingIntent.getActivity(
            this, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Content Control active")
            .setContentText("Monitoring network to detect visited domains")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
        startForeground(1, notification)
    }
    
    fun stopVpn() {
        if (isRunning.get()) {
            isRunning.set(false)
            vpnInterface?.close()
            vpnInterface = null
            Log.d(TAG, "VPN stopped")
        }
    }
    
    private fun startPacketFiltering() {
        Thread {
            try {
                val vpnInput = FileInputStream(vpnInterface?.fileDescriptor)
                val vpnOutput = FileOutputStream(vpnInterface?.fileDescriptor)
                
                val buffer = ByteArray(32767)
                
                while (isRunning.get()) {
                    val length = vpnInput.read(buffer)
                    if (length > 0) {
                        val packet = ByteBuffer.wrap(buffer, 0, length)
                        
                        if (packet.get(0).toInt() and 0xF0 shr 4 == 4) { // IPv4
                            val protocol = packet.get(9).toInt() and 0xFF
                            
                            if (protocol == 17) { // UDP
                                handleUdpPacket(packet, vpnOutput)
                            } else if (protocol == 6) { // TCP
                                handleTcpPacket(packet, vpnOutput)
                            } else {
                                vpnOutput.write(buffer, 0, length)
                            }
                        } else {
                            vpnOutput.write(buffer, 0, length)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in packet filtering: ${e.message}")
            }
        }.start()
    }
    
    private fun handleUdpPacket(packet: ByteBuffer, output: FileOutputStream) {
        try {
            val ipHeaderLen = (packet.get(0).toInt() and 0x0F) * 4
            val udpStart = ipHeaderLen
            if (packet.limit() < udpStart + 8) {
                val packetArray = ByteArray(packet.remaining())
                packet.get(packetArray)
                output.write(packetArray)
                return
            }
            
            val destPort = ((packet.get(udpStart + 2).toInt() and 0xFF) shl 8) or (packet.get(udpStart + 3).toInt() and 0xFF)
            
            if (destPort == 53) { // DNS port
                val dnsQuery = parseDnsQuery(packet, udpStart)
                if (dnsQuery != null) {
                    // Log attempted URL visit
                    logVisitedDomain(dnsQuery)
                    
                    if (isDomainBlocked(dnsQuery)) {
                        Log.d(TAG, "🚫 Blocking DNS query for: $dnsQuery")
                        // Don't forward the packet - effectively blocking it
                        return
                    }
                }
            }
            
            // Forward non-blocked packets
            val packetArray = ByteArray(packet.remaining())
            packet.get(packetArray)
            output.write(packetArray)
        } catch (e: Exception) {
            Log.e(TAG, "Error handling UDP packet: ${e.message}")
        }
    }
    
    private fun handleTcpPacket(packet: ByteBuffer, output: FileOutputStream) {
        try {
            val ipHeaderLen = (packet.get(0).toInt() and 0x0F) * 4
            val tcpStart = ipHeaderLen
            if (packet.limit() < tcpStart + 20) {
                val packetArray = ByteArray(packet.remaining())
                packet.get(packetArray)
                output.write(packetArray)
                return
            }
            
            val destPort = ((packet.get(tcpStart + 2).toInt() and 0xFF) shl 8) or (packet.get(tcpStart + 3).toInt() and 0xFF)
            val dataOffset = ((packet.get(tcpStart + 12).toInt() ushr 4) and 0x0F) * 4
            val payloadOffset = tcpStart + dataOffset
            val payloadLen = packet.limit() - payloadOffset
            
            val destIp = getDestinationIp(packet)
            if (destIp != null && isIpBlocked(destIp)) {
                Log.d(TAG, "Blocking TCP connection to: $destIp:$destPort")
                return
            }
            
            if (payloadLen > 0) {
                try {
                    val domain = when (destPort) {
                        443 -> extractSni(packet, payloadOffset, payloadLen)
                        80 -> extractHttpHost(packet, payloadOffset, payloadLen)
                        else -> null
                    }
                    
                    if (domain != null) {
                        // Log attempted URL visit
                        logVisitedDomain(domain)
                        
                        // Check if domain is blocked
                        if (isDomainBlocked(domain)) {
                            Log.d(TAG, "🚫 Blocking TCP connection to: $domain:$destPort")
                            // Don't forward the packet - effectively blocking it
                            return
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error extracting domain from TCP: ${e.message}")
                }
            }
            
            val packetArray = ByteArray(packet.remaining())
            packet.get(packetArray)
            output.write(packetArray)
        } catch (e: Exception) {
            Log.e(TAG, "Error handling TCP packet: ${e.message}")
        }
    }
    
    private fun extractHttpHost(packet: ByteBuffer, offset: Int, length: Int): String? {
        return try {
            val arr = ByteArray(length)
            val oldPos = packet.position()
            packet.position(offset)
            packet.get(arr, 0, length)
            packet.position(oldPos)
            val text = String(arr, Charsets.ISO_8859_1)
            val idx = text.indexOf("\r\nHost:", ignoreCase = true).let { if (it >= 0) it else text.indexOf("Host:", ignoreCase = true) }
            if (idx >= 0) {
                val start = text.indexOf(':', idx) + 1
                if (start > 0) {
                    val end = text.indexOf('\r', start).let { if (it >= 0) it else text.indexOf('\n', start) }
                    val host = if (end > start) text.substring(start, end).trim() else text.substring(start).trim()
                    if (host.isNotEmpty()) host else null
                } else null
            } else null
        } catch (_: Exception) { null }
    }
    
    private fun extractSni(packet: ByteBuffer, offset: Int, length: Int): String? {
        try {
            val oldPos = packet.position()
            packet.position(offset)
            if (length < 5) { packet.position(oldPos); return null }
            val contentType = packet.get().toInt() and 0xFF
            if (contentType != 22) { packet.position(oldPos); return null }
            packet.get(); packet.get(); packet.get(); packet.get()
            if (packet.remaining() < 4) { packet.position(oldPos); return null }
            val handshakeType = packet.get().toInt() and 0xFF
            if (handshakeType != 1) { packet.position(oldPos); return null }
            packet.get(); packet.get(); packet.get(); packet.get(); packet.get()
            packet.position(packet.position() + 32)
            if (packet.remaining() < 1) { packet.position(oldPos); return null }
            val sessionIdLen = packet.get().toInt() and 0xFF
            if (packet.remaining() < sessionIdLen) { packet.position(oldPos); return null }
            packet.position(packet.position() + sessionIdLen)
            if (packet.remaining() < 2) { packet.position(oldPos); return null }
            val cipherLen = ((packet.get().toInt() and 0xFF) shl 8) or (packet.get().toInt() and 0xFF)
            if (packet.remaining() < cipherLen) { packet.position(oldPos); return null }
            packet.position(packet.position() + cipherLen)
            if (packet.remaining() < 1) { packet.position(oldPos); return null }
            val compLen = packet.get().toInt() and 0xFF
            if (packet.remaining() < compLen) { packet.position(oldPos); return null }
            packet.position(packet.position() + compLen)
            if (packet.remaining() < 2) { packet.position(oldPos); return null }
            val extLen = ((packet.get().toInt() and 0xFF) shl 8) or (packet.get().toInt() and 0xFF)
            var read = 0
            while (read + 4 <= extLen && packet.remaining() >= 4) {
                val extType = ((packet.get().toInt() and 0xFF) shl 8) or (packet.get().toInt() and 0xFF)
                val extSize = ((packet.get().toInt() and 0xFF) shl 8) or (packet.get().toInt() and 0xFF)
                read += 4
                if (packet.remaining() < extSize) break
                if (extType == 0) {
                    if (extSize < 5) break
                    val sniListLen = ((packet.get().toInt() and 0xFF) shl 8) or (packet.get().toInt() and 0xFF)
                    if (packet.remaining() < sniListLen) break
                    val nameType = packet.get().toInt() and 0xFF
                    val nameLen = ((packet.get().toInt() and 0xFF) shl 8) or (packet.get().toInt() and 0xFF)
                    if (nameType == 0 && nameLen > 0 && packet.remaining() >= nameLen) {
                        val nameBytes = ByteArray(nameLen)
                        packet.get(nameBytes)
                        val host = String(nameBytes)
                        packet.position(oldPos)
                        return host
                    } else {
                        packet.position(packet.position() + (sniListLen - 3))
                    }
                } else {
                    packet.position(packet.position() + extSize)
                }
                read += extSize
            }
            packet.position(oldPos)
            return null
        } catch (e: Exception) {
            return null
        }
    }
    
    private fun parseDnsQuery(packet: ByteBuffer, udpStart: Int): String? {
        try {
            val dnsStart = udpStart + 8 // Skip UDP header
            if (packet.limit() < dnsStart + 12) return null
            
            packet.position(dnsStart)
            
            // Skip DNS header (12 bytes: ID, flags, questions, answers, authority, additional)
            packet.position(dnsStart + 12)
            
            val domain = StringBuilder()
            var length = packet.get().toInt() and 0xFF
            
            while (length != 0 && length <= 63 && packet.remaining() > 0) {
                if (domain.isNotEmpty()) {
                    domain.append(".")
                }
                if (packet.remaining() < length) break
                for (i in 0 until length) {
                    if (packet.remaining() > 0) {
                        domain.append(packet.get().toChar())
                    } else {
                        return null
                    }
                }
                if (packet.remaining() > 0) {
                    length = packet.get().toInt() and 0xFF
                } else {
                    break
                }
            }
            
            val domainStr = domain.toString().lowercase()
            return if (domainStr.isNotEmpty()) domainStr else null
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing DNS query: ${e.message}")
            return null
        }
    }
    
    private fun logVisitedDomain(domain: String) {
        try {
            // Call callback if set (from MainActivity)
            visitedUrlCallback?.invoke(domain)
        } catch (e: Exception) {
            Log.e(TAG, "Error logging visited domain: ${e.message}")
        }
    }
    
    private fun getDestinationIp(packet: ByteBuffer): String? {
        try {
            val ip1 = packet.get(16).toInt() and 0xFF
            val ip2 = packet.get(17).toInt() and 0xFF
            val ip3 = packet.get(18).toInt() and 0xFF
            val ip4 = packet.get(19).toInt() and 0xFF
            return "$ip1.$ip2.$ip3.$ip4"
        } catch (e: Exception) {
            Log.e(TAG, "Error getting destination IP: ${e.message}")
            return null
        }
    }
    
    private fun isIpBlocked(ip: String): Boolean {
        return false
    }
    
    private fun createBlockedDnsResponse(originalPacket: ByteBuffer, domain: String): ByteArray {
        // Return empty response to block the domain
        // The packet won't be forwarded, effectively blocking it
        return ByteArray(0)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
        Log.d(TAG, "VPN Service destroyed")
    }
}
