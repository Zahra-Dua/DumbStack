package com.example.parental_control_app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "child_tracking"
    private val APP_USAGE_CHANNEL = "app_usage_tracking_service"
    private val VPN_CHANNEL = "child_vpn"
    private var childTrackingChannel: MethodChannel? = null
    private var appUsageChannel: MethodChannel? = null
    private var vpnChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register all plugins
        flutterEngine.plugins.add(UrlTrackingPlugin())
       flutterEngine.plugins.add(AppListPlugin())
        flutterEngine.plugins.add(UsageStatsPlugin())
        
        // Set up child_tracking method channel
        childTrackingChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        // Set up app usage tracking method channel
        appUsageChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_USAGE_CHANNEL)
        
        // Set up VPN method channel
        vpnChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VPN_CHANNEL)
        
        // Set the child_tracking channel for UrlAccessibilityService
        UrlAccessibilityService.setChildTrackingChannel(childTrackingChannel!!)
        
        // Set method channel for AppUsageTrackingService
        AppUsageTrackingService.setMethodChannel(appUsageChannel!!)
        AppUsageTrackingService.setChildTrackingChannel(childTrackingChannel!!)
        
        // Set up URL logging callback for VPN service
        UrlBlockingVpnService.visitedUrlCallback = { domain ->
            // Send visited URL to Flutter
            vpnChannel?.invokeMethod("logVisitedUrl", mapOf("url" to domain))
        }
        
        childTrackingChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsageStatsPermission" -> {
                    result.success(checkUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(true)
                }
                "checkAccessibilityPermission" -> {
                    result.success(checkAccessibilityPermission())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(true)
                }
                "startUrlTracking" -> {
                    android.util.Log.d("MainActivity", "📞 [Native] Received startUrlTracking call from Flutter")
                    startUrlTracking()
                    result.success(true)
                }
                "startAppUsageTracking" -> {
                    android.util.Log.d("MainActivity", "📞 [Native] Received startAppUsageTracking call from Flutter")
                    startAppUsageTracking()
                    result.success(true)
                }
                "stopAllTracking" -> {
                    stopAllTracking()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up VPN method channel handler
        vpnChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestVpnPermission" -> {
                    val intent = android.net.VpnService.prepare(this)
                    if (intent != null) {
                        // Need to request permission
                        startActivityForResult(intent, 100)
                        result.success(false)
                    } else {
                        // Permission already granted
                        result.success(true)
                    }
                }
                "startVpn" -> {
                    val vpnIntent = Intent(this, UrlBlockingVpnService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(vpnIntent)
                    } else {
                        startService(vpnIntent)
                    }
                    result.success(null)
                }
                "stopVpn" -> {
                    val vpnIntent = Intent(this, UrlBlockingVpnService::class.java)
                    stopService(vpnIntent)
                    result.success(null)
                }
                "updateBlockedUrls" -> {
                    val urls = call.argument<List<String>>("urls") ?: emptyList()
                    // Clear old domains and set new ones
                    UrlBlockingVpnService.clearBlockedDomains()
                    urls.forEach { domain ->
                        UrlBlockingVpnService.addBlockedDomain(domain)
                    }
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 100) {
            // VPN permission result
            if (resultCode == RESULT_OK) {
                // Permission granted, start VPN
                val vpnIntent = Intent(this, UrlBlockingVpnService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(vpnIntent)
                } else {
                    startService(vpnIntent)
                }
            }
        }
    }

    private fun checkUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun checkAccessibilityPermission(): Boolean {
        val accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains("${packageName}/${UrlAccessibilityService::class.java.name}") == true
    }

    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun startUrlTracking() {
        android.util.Log.d("MainActivity", "")
        android.util.Log.d("MainActivity", "🌐 ========== 🌐 STARTING URL TRACKING 🌐 ==========")
        android.util.Log.d("MainActivity", "🌐 [Native] Starting URL tracking service...")
        
        // Check if accessibility permission is granted first
        val hasAccessibility = checkAccessibilityPermission()
        if (hasAccessibility) {
            android.util.Log.d("MainActivity", "✅ [Native] Accessibility permission: GRANTED")
        } else {
            android.util.Log.w("MainActivity", "⚠️ [Native] Accessibility permission: NOT GRANTED")
            android.util.Log.w("MainActivity", "⚠️ [Native] URL tracking will NOT work without this permission!")
            android.util.Log.w("MainActivity", "⚠️ [Native] Please enable SafeNest in Settings > Accessibility")
        }
        
        // Start accessibility service for URL tracking
        val intent = Intent(this, UrlAccessibilityService::class.java)
        startService(intent)
        android.util.Log.d("MainActivity", "✅ [Native] URL tracking service intent sent")
        android.util.Log.d("MainActivity", "🌐 ==============================================")
        android.util.Log.d("MainActivity", "")
    }

    private fun startAppUsageTracking() {
        android.util.Log.d("MainActivity", "📱 [Native] Starting app usage tracking service...")
        // Start real-time app usage tracking service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val intent = Intent(this, AppUsageTrackingService::class.java).apply {
                action = AppUsageTrackingService.ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            android.util.Log.d("MainActivity", "✅ [Native] App usage tracking service started")
        } else {
            android.util.Log.e("MainActivity", "❌ [Native] App usage tracking not supported on this Android version")
        }
    }

    private fun stopAllTracking() {
        // Stop all tracking services
        val intent = Intent(this, UrlAccessibilityService::class.java)
        stopService(intent)
    }
}
