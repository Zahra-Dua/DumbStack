package com.example.parental_control_app

import android.accessibilityservice.AccessibilityService
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class UrlTrackingPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var vpnService: UrlBlockingVpnService? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "url_tracking")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        // Set the method channel for the accessibility service
        UrlAccessibilityService.setMethodChannel(channel)
        
        // Initialize VPN service
        vpnService = UrlBlockingVpnService()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "hasUsageStatsPermission" -> {
                result.success(hasUsageStatsPermission())
            }
            "requestUsageStatsPermission" -> {
                requestUsageStatsPermission()
                result.success(null)
            }
            "getRecentBrowserActivity" -> {
                val duration = call.argument<Long>("duration") ?: 86400000L // 24 hours default
                val activity = getRecentBrowserActivity(duration)
                result.success(activity)
            }
            "requestAccessibilityPermission" -> {
                requestAccessibilityPermission()
                result.success(null)
            }
            "hasAccessibilityPermission" -> {
                result.success(hasAccessibilityPermission())
            }
            "startVpnBlocking" -> {
                startVpnBlocking()
                result.success(null)
            }
            "stopVpnBlocking" -> {
                stopVpnBlocking()
                result.success(null)
            }
            "addBlockedDomain" -> {
                val domain = call.argument<String>("domain")
                if (domain != null) {
                    addBlockedDomain(domain)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Domain is required", null)
                }
            }
            "removeBlockedDomain" -> {
                val domain = call.argument<String>("domain")
                if (domain != null) {
                    removeBlockedDomain(domain)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Domain is required", null)
                }
            }
            "getBlockedDomains" -> {
                result.success(getBlockedDomains())
            }
            "clearBlockedDomains" -> {
                clearBlockedDomains()
                result.success(null)
            }
            "testUrlDetection" -> {
                testUrlDetection()
                result.success(null)
            }
            "getForegroundPackage" -> {
                result.success(getForegroundPackage())
            }
            "setAppRestriction" -> {
                val pkg = call.argument<String>("packageName")
                val until = call.argument<Long>("untilMs")
                if (pkg != null && until != null) {
                    UrlAccessibilityService.setAppRestriction(pkg, until)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "packageName and untilMs required", null)
                }
            }
            "clearAppRestriction" -> {
                val pkg = call.argument<String>("packageName")
                if (pkg != null) {
                    UrlAccessibilityService.clearAppRestriction(pkg)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "packageName required", null)
                }
            }
            "clearAllRestrictions" -> {
                UrlAccessibilityService.clearAllRestrictions()
                result.success(true)
            }
            "setGlobalRestriction" -> {
                val until = call.argument<Long>("untilMs")
                if (until != null) {
                    UrlAccessibilityService.setGlobalRestriction(until)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "untilMs required", null)
                }
            }
            "clearGlobalRestriction" -> {
                UrlAccessibilityService.clearGlobalRestriction()
                result.success(true)
            }
            "setGlobalDailyLimitMinutes" -> {
                val minutes = call.argument<Int>("minutes") ?: 0
                val prefs = context.getSharedPreferences("content_control_prefs", Context.MODE_PRIVATE)
                prefs.edit().putInt("global_daily_limit_minutes", minutes).apply()
                result.success(true)
            }
            "clearGlobalDailyLimitMinutes" -> {
                val prefs = context.getSharedPreferences("content_control_prefs", Context.MODE_PRIVATE)
                prefs.edit().putInt("global_daily_limit_minutes", 0).apply()
                UrlAccessibilityService.clearGlobalRestriction()
                result.success(true)
            }
            "isAppRestricted" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val isRestricted = UrlAccessibilityService.isRestricted(packageName)
                    result.success(isRestricted)
                } else {
                    result.error("INVALID_ARGUMENT", "Package name is required", null)
                }
            }
            "checkAppRestrictionImmediately" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENT", "Package name is required", null)
                }
            }
            "forceCloseApp" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    try {
                        val accessibilityService = UrlAccessibilityService.serviceInstance
                        if (accessibilityService != null) {
                            for (i in 1..3) {
                                accessibilityService.performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
                                Thread.sleep(200)
                            }
                            Log.d("UrlTrackingPlugin", "🚫 FORCE CLOSED app: $packageName")
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("UrlTrackingPlugin", "Error force closing app: ${e.message}")
                        result.error("FORCE_CLOSE_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Package name is required", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = appOps.checkOpNoThrow(
            android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun getRecentBrowserActivity(duration: Long): List<Map<String, Any>> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - duration
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        val browserPackages = listOf(
            "com.android.chrome",
            "org.mozilla.firefox",
            "com.microsoft.emmx",
            "com.opera.browser",
            "com.sec.android.app.sbrowser",
            "com.UCMobile.intl",
            "com.brave.browser"
        )
        val browserActivity = mutableListOf<Map<String, Any>>()
        for (stat in usageStats) {
            if (browserPackages.contains(stat.packageName)) {
                browserActivity.add(mapOf(
                    "packageName" to stat.packageName,
                    "lastTimeUsed" to stat.lastTimeUsed,
                    "totalTimeInForeground" to stat.totalTimeInForeground,
                    "appName" to getAppName(stat.packageName)
                ))
            }
        }
        return browserActivity.sortedByDescending { it["lastTimeUsed"] as Long }
    }

    private fun getAppName(packageName: String): String {
        return when (packageName) {
            "com.android.chrome" -> "Google Chrome"
            "org.mozilla.firefox" -> "Mozilla Firefox"
            "com.microsoft.emmx" -> "Microsoft Edge"
            "com.opera.browser" -> "Opera Browser"
            "com.sec.android.app.sbrowser" -> "Samsung Internet"
            "com.UCMobile.intl" -> "UC Browser"
            "com.brave.browser" -> "Brave Browser"
            else -> "Unknown Browser"
        }
    }

    private fun getForegroundPackage(): String? {
        return try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val end = System.currentTimeMillis()
            val start = end - 10_000
            val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
            if (stats.isNullOrEmpty()) return null
            val last = stats.maxByOrNull { it.lastTimeUsed }
            last?.packageName
        } catch (e: Exception) {
            Log.e("UrlTrackingPlugin", "getForegroundPackage error: ${e.message}")
            null
        }
    }

    private fun hasAccessibilityPermission(): Boolean {
        val accessibilityManager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains("${context.packageName}/${UrlAccessibilityService::class.java.name}") == true
    }

    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun startVpnBlocking() {
        try {
            val intent = Intent(context, UrlBlockingVpnService::class.java)
            context.startService(intent)
        } catch (e: Exception) {
            Log.e("UrlTrackingPlugin", "Error starting VPN service: ${e.message}")
        }
    }

    private fun stopVpnBlocking() {
        try {
            val intent = Intent(context, UrlBlockingVpnService::class.java)
            context.stopService(intent)
        } catch (e: Exception) {
            Log.e("UrlTrackingPlugin", "Error stopping VPN service: ${e.message}")
        }
    }

    private fun addBlockedDomain(domain: String) {
        UrlBlockingVpnService.addBlockedDomain(domain)
    }

    private fun removeBlockedDomain(domain: String) {
        UrlBlockingVpnService.removeBlockedDomain(domain)
    }

    private fun getBlockedDomains(): List<String> {
        return UrlBlockingVpnService.getBlockedDomains().toList()
    }

    private fun clearBlockedDomains() {
        UrlBlockingVpnService.clearBlockedDomains()
    }

    private fun testUrlDetection() {
        Log.d("UrlTrackingPlugin", "Testing URL detection...")
        channel.invokeMethod("onUrlDetected", mapOf(
            "url" to "https://www.google.com",
            "packageName" to "com.android.chrome",
            "timestamp" to System.currentTimeMillis()
        ))
        Log.d("UrlTrackingPlugin", "Test URL sent to Flutter")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

