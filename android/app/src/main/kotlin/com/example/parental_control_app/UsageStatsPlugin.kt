package com.example.parental_control_app

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class UsageStatsPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var packageManager: PackageManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "usage_stats_service")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        packageManager = context.packageManager
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
            "getAppUsageStats" -> {
                val startTime = call.argument<Long>("startTime") ?: 0L
                val endTime = call.argument<Long>("endTime") ?: 0L
                val stats = getAppUsageStats(startTime, endTime)
                result.success(stats)
            }
            "getTodayUnlockCount" -> {
                result.success(getTodayUnlockCount())
            }
            "getWeeklyUnlockCount" -> {
                result.success(getWeeklyUnlockCount())
            }
            "getCurrentForegroundApp" -> {
                result.success(getCurrentForegroundApp())
            }
            "startMonitoring" -> {
                startMonitoring()
                result.success(null)
            }
            "stopMonitoring" -> {
                stopMonitoring()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun getAppUsageStats(startTime: Long, endTime: Long): List<Map<String, Any>> {
        try {
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            val appStatsMap = mutableMapOf<String, MutableMap<String, Any>>()
            for (stat in usageStats) {
                val packageName = stat.packageName
                
                if (appStatsMap.containsKey(packageName)) {
                    val existing = appStatsMap[packageName]!!
                    val newTime = (existing["totalTimeInForeground"] as Long) + stat.totalTimeInForeground
                    existing["totalTimeInForeground"] = newTime
                    existing["foregroundTime"] = newTime
                    if (stat.lastTimeUsed > (existing["lastTimeUsed"] as Long)) {
                        existing["lastTimeUsed"] = stat.lastTimeUsed
                    }
                } else {
                    val appName = getAppName(packageName)
                    appStatsMap[packageName] = mutableMapOf<String, Any>(
                        "packageName" to packageName,
                        "appName" to appName,
                        "totalTimeInForeground" to stat.totalTimeInForeground,
                        "foregroundTime" to stat.totalTimeInForeground,
                        "lastTimeUsed" to stat.lastTimeUsed,
                        "launchCount" to 0,
                        "iconPath" to ""
                    )
                }
            }
            return appStatsMap.values.toList()
        } catch (e: Exception) {
            Log.e("UsageStatsPlugin", "Error getting app usage stats: ${e.message}")
            return emptyList()
        }
    }

    private fun getAppName(packageName: String): String {
        return try {
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            Log.w("UsageStatsPlugin", "Could not get app name for $packageName: ${e.message}")
            packageName
        }
    }

    private fun getTodayUnlockCount(): Int {
        return try {
            val prefs = context.getSharedPreferences("usage_stats", Context.MODE_PRIVATE)
            prefs.getInt("today_unlocks", 0)
        } catch (e: Exception) {
            Log.e("UsageStatsPlugin", "Error getting today unlock count: ${e.message}")
            0
        }
    }

    private fun getWeeklyUnlockCount(): Int {
        return try {
            val prefs = context.getSharedPreferences("usage_stats", Context.MODE_PRIVATE)
            prefs.getInt("week_unlocks", 0)
        } catch (e: Exception) {
            Log.e("UsageStatsPlugin", "Error getting weekly unlock count: ${e.message}")
            0
        }
    }

    private fun getCurrentForegroundApp(): String? {
        return try {
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                System.currentTimeMillis() - 10000,
                System.currentTimeMillis()
            )
            
            if (usageStats.isNotEmpty()) {
                val lastUsed = usageStats.maxByOrNull { it.lastTimeUsed }
                lastUsed?.packageName
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e("UsageStatsPlugin", "Error getting current foreground app: ${e.message}")
            null
        }
    }

    private fun startMonitoring() {
        Log.d("UsageStatsPlugin", "Started monitoring app usage")
    }

    private fun stopMonitoring() {
        Log.d("UsageStatsPlugin", "Stopped monitoring app usage")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

