package com.example.parental_control_app

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import android.os.Handler
import android.os.Looper
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class AppListPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "app_list_service")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInstalledApps" -> {
                runInBackground(
                    task = { getInstalledApps() },
                    onSuccess = { apps -> result.success(apps) },
                    onError = { e ->
                        Log.e("AppListPlugin", "Error getting installed apps", e)
                        result.error("ERROR", "Failed to get installed apps", e.message)
                    }
                )
            }
            "getUserApps" -> {
                runInBackground(
                    task = { getUserApps() },
                    onSuccess = { apps -> result.success(apps) },
                    onError = { e ->
                        Log.e("AppListPlugin", "Error getting user apps", e)
                        result.error("ERROR", "Failed to get user apps", e.message)
                    }
                )
            }
            "getSystemApps" -> {
                runInBackground(
                    task = { getSystemApps() },
                    onSuccess = { apps -> result.success(apps) },
                    onError = { e ->
                        Log.e("AppListPlugin", "Error getting system apps", e)
                        result.error("ERROR", "Failed to get system apps", e.message)
                    }
                )
            }
            "launchApp" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    result.success(launchApp(packageName))
                } else {
                    result.error("ERROR", "Package name is required", null)
                }
            }
            "uninstallApp" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    result.success(uninstallApp(packageName))
                } else {
                    result.error("ERROR", "Package name is required", null)
                }
            }
            "getUsageStats" -> {
                Thread {
                    val days = call.argument<Int>("days") ?: 1
                    getUsageStats(days, result)
                }.start()
            }
            "getAppUsageStats" -> {
                Thread {
                    val packageName = call.argument<String>("packageName")
                    val days = call.argument<Int>("days") ?: 1
                    if (packageName != null) {
                        getAppUsageStats(packageName, days, result)
                    } else {
                        Handler(Looper.getMainLooper()).post {
                            result.error("INVALID_ARGUMENT", "Package name is required", null)
                        }
                    }
                }.start()
            }
            "getTotalScreenTime" -> {
                Thread {
                    val days = call.argument<Int>("days") ?: 1
                    getTotalScreenTime(days, result)
                }.start()
            }
            "getAppInfo" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName == null) {
                    result.error("ERROR", "Package name is required", null)
                } else {
                    runInBackground(
                        task = { getAppInfo(packageName) },
                        onSuccess = { appInfo -> result.success(appInfo) },
                        onError = { e ->
                            Log.e("AppListPlugin", "Error getting app info", e)
                            result.error("ERROR", "Failed to get app info", e.message)
                        }
                    )
                }
            }
            "isAppInstalled" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    result.success(isAppInstalled(packageName))
                } else {
                    result.error("ERROR", "Package name is required", null)
                }
            }
            "hasUsageStatsPermission" -> {
                result.success(hasUsageStatsPermission())
            }
            "requestUsageStatsPermission" -> {
                requestUsageStatsPermission()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val packageManager = context.packageManager
        val apps = mutableListOf<Map<String, Any?>>()

        try {
            Log.d("AppListPlugin", "Getting installed apps...")

            // Try to get all installed applications
            try {
                val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
                Log.d("AppListPlugin", "Found ${packages.size} apps using getInstalledApplications")

                for (appInfo in packages) {
                    try {
                        val packageInfo: PackageInfo = try {
                            packageManager.getPackageInfo(appInfo.packageName, PackageManager.GET_META_DATA)
                        } catch (e: Exception) {
                            // Fallback to no flags if GET_META_DATA fails on some APIs
                            packageManager.getPackageInfo(appInfo.packageName, 0)
                        }

                        val isSystemApp = ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
                        val appName = packageManager.getApplicationLabel(appInfo).toString()

                        apps.add(
                            mapOf(
                                "packageName" to appInfo.packageName,
                                "appName" to appName,
                                "versionName" to packageInfo.versionName,
                                "versionCode" to packageInfo.longVersionCode,
                                "isSystemApp" to isSystemApp,
                                "installTime" to packageInfo.firstInstallTime,
                                "lastUpdateTime" to packageInfo.lastUpdateTime,
                                "iconPath" to null
                            )
                        )
                    } catch (e: Exception) {
                        Log.w("AppListPlugin", "Error getting info for ${appInfo.packageName}: ${e.message}")
                    }
                }
            } catch (se: SecurityException) {
                Log.w("AppListPlugin", "SecurityException reading installed apps (missing QUERY_ALL_PACKAGES?): ${se.message}")
            }

            // If no apps found (or SecurityException), fallback to launcher activities (apps shown in launcher)
            if (apps.isEmpty()) {
                Log.w("AppListPlugin", "No apps found with getInstalledApplications or security blocked, trying launcher apps fallback...")
                val intent = Intent(Intent.ACTION_MAIN, null)
                intent.addCategory(Intent.CATEGORY_LAUNCHER)
                val launcherApps = packageManager.queryIntentActivities(intent, 0)

                val seen = HashSet<String>()
                for (info in launcherApps) {
                    try {
                        val ai = info.activityInfo.applicationInfo
                        if (seen.add(ai.packageName)) {
                            val packageInfo: PackageInfo = try {
                                packageManager.getPackageInfo(ai.packageName, PackageManager.GET_META_DATA)
                            } catch (e: Exception) {
                                packageManager.getPackageInfo(ai.packageName, 0)
                            }
                            val appName = packageManager.getApplicationLabel(ai).toString()
                            val isSystemApp = ((ai.flags and ApplicationInfo.FLAG_SYSTEM) != 0)

                            apps.add(
                                mapOf(
                                    "packageName" to ai.packageName,
                                    "appName" to appName,
                                    "versionName" to packageInfo.versionName,
                                    "versionCode" to packageInfo.longVersionCode,
                                    "isSystemApp" to isSystemApp,
                                    "installTime" to packageInfo.firstInstallTime,
                                    "lastUpdateTime" to packageInfo.lastUpdateTime,
                                    "iconPath" to null
                                )
                            )
                        }
                    } catch (e: Exception) {
                        Log.w("AppListPlugin", "Error in fallback for ${info.activityInfo.packageName}: ${e.message}")
                    }
                }
                Log.d("AppListPlugin", "Fallback found ${apps.size} launcher apps")
            }

            Log.d("AppListPlugin", "✅ Total apps returned: ${apps.size}")
            if (apps.isNotEmpty()) {
                for (i in 0 until minOf(5, apps.size)) {
                    val app = apps[i]
                    Log.d("AppListPlugin", "  ${i + 1}. ${app["appName"]} (${app["packageName"]})")
                }
            }

        } catch (e: Exception) {
            Log.e("AppListPlugin", "❌ Error getting installed apps: ${e.message}", e)
        }

        return apps
    }

    private fun <T> runInBackground(
        task: () -> T,
        onSuccess: (T) -> Unit,
        onError: (Exception) -> Unit
    ) {
        Thread {
            try {
                val result = task()
                Handler(Looper.getMainLooper()).post { onSuccess(result) }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post { onError(e) }
            }
        }.start()
    }

    private fun getUserApps(): List<Map<String, Any?>> {
        return getInstalledApps().filter { app ->
            !(app["isSystemApp"] as Boolean)
        }
    }

    private fun getSystemApps(): List<Map<String, Any?>> {
        return getInstalledApps().filter { app ->
            (app["isSystemApp"] as Boolean)
        }
    }

    private fun launchApp(packageName: String): Boolean {
        return try {
            val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e("AppListPlugin", "Error launching app: $packageName", e)
            false
        }
    }

    private fun uninstallApp(packageName: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_DELETE)
            intent.data = Uri.parse("package:$packageName")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e("AppListPlugin", "Error uninstalling app: $packageName", e)
            false
        }
    }

    private fun getAppInfo(packageName: String): Map<String, Any?>? {
        return try {
            val packageManager = context.packageManager
            val packageInfo = try {
                packageManager.getPackageInfo(packageName, PackageManager.GET_META_DATA)
            } catch (e: Exception) {
                packageManager.getPackageInfo(packageName, 0)
            }
            val appInfo: ApplicationInfo? = packageInfo.applicationInfo
            val isSystemApp = (((appInfo?.flags ?: 0) and ApplicationInfo.FLAG_SYSTEM) != 0)
            val appName = appInfo?.let { packageManager.getApplicationLabel(it).toString() }
                ?: packageInfo.packageName
            mapOf(
                "packageName" to packageInfo.packageName,
                "appName" to appName,
                "versionName" to packageInfo.versionName,
                "versionCode" to packageInfo.longVersionCode,
                "isSystemApp" to isSystemApp,
                "installTime" to packageInfo.firstInstallTime,
                "lastUpdateTime" to packageInfo.lastUpdateTime
            )
        } catch (e: Exception) {
            Log.e("AppListPlugin", "Error getting app info: $packageName", e)
            null
        }
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ---- usage stats functions kept the same as your original file ----
    private fun getUsageStats(days: Int, result: Result) {
        // (existing implementation you provided)
        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - (days * 24 * 60 * 60 * 1000L)
            var finalUsageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_BEST,
                startTime,
                endTime
            )

            if (finalUsageStatsList.isNullOrEmpty()) {
                finalUsageStatsList = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    startTime,
                    endTime
                )
            }

            val packageManager = context.packageManager
            val appUsageList = mutableListOf<Map<String, Any>>()
            var totalScreenTime = 0L
            var totalPhoneUsage = 0L
            finalUsageStatsList?.forEach { usageStats ->
                try {
                    val applicationInfo = packageManager.getApplicationInfo(usageStats.packageName, 0)
                    val appName = packageManager.getApplicationLabel(applicationInfo).toString()
                    val events = usageStatsManager.queryEvents(startTime, endTime)
                    var launchCount = 0
                    val event = UsageEvents.Event()
                    while (events.hasNextEvent()) {
                        events.getNextEvent(event)
                        if (event.packageName == usageStats.packageName &&
                            event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                            launchCount++
                        }
                    }
                    val appUsageMap = mapOf(
                        "packageName" to usageStats.packageName,
                        "appName" to appName,
                        "totalTimeInForeground" to usageStats.totalTimeInForeground,
                        "lastTimeUsed" to usageStats.lastTimeUsed,
                        "launchCount" to launchCount,
                        "firstTimeStamp" to usageStats.firstTimeStamp,
                        "lastTimeStamp" to usageStats.lastTimeStamp
                    )
                    appUsageList.add(appUsageMap)
                    totalScreenTime += usageStats.totalTimeInForeground
                    totalPhoneUsage += usageStats.totalTimeInForeground
                } catch (e: Exception) {
                    Log.w("AppListPlugin", "Could not get info for package: ${usageStats.packageName}")
                }
            }
            appUsageList.sortByDescending { (it["totalTimeInForeground"] as Long) }
            val deviceUsageStats = mapOf(
                "totalScreenTime" to totalScreenTime,
                "totalPhoneUsage" to totalPhoneUsage,
                "date" to System.currentTimeMillis(),
                "appUsageStats" to appUsageList
            )
            Handler(Looper.getMainLooper()).post {
                result.success(deviceUsageStats)
            }
        } catch (e: Exception) {
            Log.e("AppListPlugin", "Error getting usage stats", e)
            Handler(Looper.getMainLooper()).post {
                result.error("ERROR", "Failed to get usage stats: ${e.message}", null)
            }
        }
    }

    private fun getAppUsageStats(packageName: String, days: Int, result: Result) {
        // keep your existing implementation (unchanged)
        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - (days * 24 * 60 * 60 * 1000L)
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            val usageStats = usageStatsList?.find { it.packageName == packageName }
            if (usageStats != null) {
                try {
                    val packageManager = context.packageManager
                    val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
                    val appName = packageManager.getApplicationLabel(applicationInfo).toString()
                    val events = usageStatsManager.queryEvents(startTime, endTime)
                    var launchCount = 0
                    val event = UsageEvents.Event()
                    while (events.hasNextEvent()) {
                        events.getNextEvent(event)
                        if (event.packageName == packageName &&
                            event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                            launchCount++
                        }
                    }
                    val appUsageMap = mapOf(
                        "packageName" to usageStats.packageName,
                        "appName" to appName,
                        "totalTimeInForeground" to usageStats.totalTimeInForeground,
                        "lastTimeUsed" to usageStats.lastTimeUsed,
                        "launchCount" to launchCount,
                        "firstTimeStamp" to usageStats.firstTimeStamp,
                        "lastTimeStamp" to usageStats.lastTimeStamp
                    )
                    Handler(Looper.getMainLooper()).post {
                        result.success(appUsageMap)
                    }
                } catch (e: Exception) {
                    Handler(Looper.getMainLooper()).post {
                        result.error("ERROR", "App not found or no usage data", null)
                    }
                }
            } else {
                Handler(Looper.getMainLooper()).post {
                    result.error("ERROR", "No usage data found for this app", null)
                }
            }
        } catch (e: Exception) {
            Log.e("AppListPlugin", "Error getting app usage stats", e)
            Handler(Looper.getMainLooper()).post {
                result.error("ERROR", "Failed to get app usage stats: ${e.message}", null)
            }
        }
    }

    private fun getTotalScreenTime(days: Int, result: Result) {
        // same as your existing implementation
        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - (days * 24 * 60 * 60 * 1000L)
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            var totalScreenTime = 0L
            usageStatsList?.forEach { usageStats ->
                totalScreenTime += usageStats.totalTimeInForeground
            }
            val screenTimeMap = mapOf(
                "totalScreenTime" to totalScreenTime,
                "days" to days,
                "startTime" to startTime,
                "endTime" to endTime
            )
            Handler(Looper.getMainLooper()).post {
                result.success(screenTimeMap)
            }
        } catch (e: Exception) {
            Log.e("AppListPlugin", "Error getting total screen time", e)
            Handler(Looper.getMainLooper()).post {
                result.error("ERROR", "Failed to get total screen time: ${e.message}", null)
            }
        }
    }
}
