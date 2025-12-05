package com.example.parental_control_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED == intent.action) {
            try {
                val prefs = context.getSharedPreferences("content_control_prefs", Context.MODE_PRIVATE)
                val shouldStart = prefs.getBoolean("tracking_enabled", false)
                if (shouldStart) {
                    Log.d("BootReceiver", "Tracking enabled flag found; starting VPN service")
                    val serviceIntent = Intent(context, UrlBlockingVpnService::class.java)
                    context.startForegroundService(serviceIntent)
                } else {
                    Log.d("BootReceiver", "Tracking not enabled; skipping service start")
                }
            } catch (e: Exception) {
                Log.e("BootReceiver", "Error starting service on boot: ${e.message}")
            }
        }
    }
}
