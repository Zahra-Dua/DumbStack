package com.example.parental_control_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
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
                    // startForegroundService() is only available on API 26+ (Android 8.0+)
                    // Use startService() as fallback for older versions (API 23-25)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                } else {
                    Log.d("BootReceiver", "Tracking not enabled; skipping service start")
                }
            } catch (e: Exception) {
                Log.e("BootReceiver", "Error starting service on boot: ${e.message}")
            }
        }
    }
}
