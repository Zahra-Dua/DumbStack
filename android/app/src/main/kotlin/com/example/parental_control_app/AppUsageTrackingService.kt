package com.example.parental_control_app

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel
import java.util.*

/**
 * Real-time App Usage Tracking Service
 * 
 * This service continuously monitors app usage and sends updates to Flutter
 * Features:
 * - Real-time foreground app detection
 * - App usage time tracking
 * - App launch detection
 * - Periodic sync to Flutter
 */
@RequiresApi(Build.VERSION_CODES.LOLLIPOP_MR1)
class AppUsageTrackingService : Service() {
    
    private var usageStatsManager: UsageStatsManager? = null
    private var handler: Handler? = null
    private var runnable: Runnable? = null
    
    // Tracking variables
    private var currentForegroundApp: String? = null
    private var appStartTime: Long = 0
    private val appUsageMap = mutableMapOf<String, AppUsageData>()
    
    // Configuration
    private val CHECK_INTERVAL_MS = 2000L // Check every 2 seconds
    private val SYNC_INTERVAL_MS = 30000L // Sync to Flutter every 30 seconds
    
    private var lastSyncTime = 0L
    
    companion object {
        private const val TAG = "AppUsageTrackingService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "app_usage_tracking_channel"
        
        // Action constants
        const val ACTION_START = "com.example.parental_control_app.START_TRACKING"
        const val ACTION_STOP = "com.example.parental_control_app.STOP_TRACKING"
        
        // Method channel for Flutter communication
        private var methodChannel: MethodChannel? = null
        private var childTrackingChannel: MethodChannel? = null
        
        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
            Log.d(TAG, "✅ [Native] App usage method channel set from MainActivity")
        }
        
        fun setChildTrackingChannel(channel: MethodChannel) {
            childTrackingChannel = channel
            Log.d(TAG, "✅ [Native] Child tracking channel set for app usage events")
        }
        
        fun getMethodChannel(): MethodChannel? = methodChannel
        fun getChildTrackingChannel(): MethodChannel? = childTrackingChannel
    }
    
    data class AppUsageData(
        var packageName: String,
        var appName: String,
        var totalUsageTime: Long = 0, // in milliseconds
        var launchCount: Int = 0,
        var lastUsed: Long = System.currentTimeMillis(),
        var isSystemApp: Boolean = false
    )
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        handler = Handler(Looper.getMainLooper())
        
        // Create notification channel for foreground service
        createNotificationChannel()
        
        // Start as foreground service
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Initialize Flutter method channel
        initializeFlutterChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                Log.d(TAG, "Starting app usage tracking")
                startTracking()
            }
            ACTION_STOP -> {
                Log.d(TAG, "Stopping app usage tracking")
                stopTracking()
                stopSelf()
            }
        }
        return START_STICKY // Restart if killed
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Usage Tracking",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracks app usage in real-time"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("App Usage Tracking")
            .setContentText("Monitoring app usage...")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    private fun initializeFlutterChannel() {
        // Method channel is set from MainActivity via companion object
        Log.d(TAG, "Flutter channel initialized")
    }
    
    private fun startTracking() {
        if (runnable != null) {
            Log.w(TAG, "⚠️ [Native] Tracking already started")
            return
        }
        
        Log.d(TAG, "")
        Log.d(TAG, "📱 ========== 📱 STARTING APP USAGE TRACKING 📱 ==========")
        Log.d(TAG, "📱 Service: AppUsageTrackingService")
        Log.d(TAG, "📱 Check Interval: ${CHECK_INTERVAL_MS}ms (every 2 seconds)")
        Log.d(TAG, "📱 Sync Interval: ${SYNC_INTERVAL_MS}ms (every 30 seconds)")
        Log.d(TAG, "📱 ====================================================")
        
        runnable = object : Runnable {
            override fun run() {
                try {
                    checkForegroundApp()
                    checkSyncToFlutter()
                } catch (e: Exception) {
                    Log.e(TAG, "❌ [Native] Error in tracking loop: ${e.message}")
                } finally {
                    handler?.postDelayed(this, CHECK_INTERVAL_MS)
                }
            }
        }
        
        handler?.post(runnable!!)
        Log.d(TAG, "✅ [Native] App usage tracking started successfully")
        Log.d(TAG, "✅ [Native] Now monitoring all app launches and usage")
        Log.d(TAG, "")
    }
    
    private fun stopTracking() {
        Log.d(TAG, "Stopping app usage tracking")
        runnable?.let { handler?.removeCallbacks(it) }
        runnable = null
        
        // Final sync before stopping
        syncToFlutter()
    }
    
    private fun checkForegroundApp() {
        try {
            val currentTime = System.currentTimeMillis()
            val foregroundApp = getCurrentForegroundApp()
            
            // If app changed, update usage for previous app
            if (foregroundApp != currentForegroundApp) {
                if (currentForegroundApp != null && appStartTime > 0) {
                    val usageTime = currentTime - appStartTime
                    updateAppUsage(currentForegroundApp!!, usageTime)
                }
                
                // Start tracking new app
                currentForegroundApp = foregroundApp
                appStartTime = currentTime
                
                if (foregroundApp != null) {
                    // Notify Flutter about app change
                    notifyAppChanged(foregroundApp)
                    
                    // Increment launch count
                    val appData = appUsageMap.getOrPut(foregroundApp) {
                        AppUsageData(
                            packageName = foregroundApp,
                            appName = getAppName(foregroundApp)
                        )
                    }
                    appData.launchCount++
                }
            } else if (foregroundApp != null) {
                // Same app, update current usage time
                val usageTime = currentTime - appStartTime
                val appData = appUsageMap.getOrPut(foregroundApp) {
                    AppUsageData(
                        packageName = foregroundApp,
                        appName = getAppName(foregroundApp)
                    )
                }
                appData.totalUsageTime += usageTime
                appData.lastUsed = currentTime
                appStartTime = currentTime // Reset start time
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking foreground app: ${e.message}")
        }
    }
    
    private fun getCurrentForegroundApp(): String? {
        return try {
            val currentTime = System.currentTimeMillis()
            val usageStats = usageStatsManager?.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                currentTime - 10000, // Last 10 seconds
                currentTime
            )
            
            usageStats?.maxByOrNull { it.lastTimeUsed }?.packageName
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app: ${e.message}")
            null
        }
    }
    
    private fun updateAppUsage(packageName: String, usageTime: Long) {
        val appData = appUsageMap.getOrPut(packageName) {
            AppUsageData(
                packageName = packageName,
                appName = getAppName(packageName)
            )
        }
        
        appData.totalUsageTime += usageTime
        appData.lastUsed = System.currentTimeMillis()
        
        Log.d(TAG, "Updated usage for $packageName: +${usageTime}ms (Total: ${appData.totalUsageTime}ms)")
    }
    
    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }
    
    private fun notifyAppChanged(packageName: String) {
        try {
            val appName = getAppName(packageName)
            val isSystemApp = isSystemApp(packageName)
            
            Log.d(TAG, "")
            Log.d(TAG, "📱 ========== 📱 APP OPENED - NATIVE SIDE 📱 ==========")
            Log.d(TAG, "📱 App Name: $appName")
            Log.d(TAG, "📱 Package: $packageName")
            Log.d(TAG, "📱 Is System App: $isSystemApp")
            Log.d(TAG, "📱 ====================================================")
            
            val data = mapOf(
                "packageName" to packageName,
                "appName" to appName,
                "isSystemApp" to isSystemApp,
                "timestamp" to System.currentTimeMillis()
            )
            
            // Send to app_usage_tracking_service channel (for RealTimeAppUsageService)
            AppUsageTrackingService.getMethodChannel()?.invokeMethod("onAppChanged", data)
            Log.d(TAG, "✅ [Native] Sent app change to app_usage_tracking_service channel: $appName")
            
            // Also send to child_tracking channel (for RealDataCollectionService)
            val childTrackingData = mapOf(
                "packageName" to packageName,
                "appName" to appName,
                "usageDuration" to 0,
                "launchCount" to 1,
                "lastUsed" to System.currentTimeMillis(),
                "isSystemApp" to isSystemApp
            )
            
            Handler(Looper.getMainLooper()).post {
                try {
                    AppUsageTrackingService.getChildTrackingChannel()?.invokeMethod("onAppLaunched", childTrackingData)
                    Log.d(TAG, "✅ [Native] Sent app launch to child_tracking channel: $appName")
                    Log.d(TAG, "✅ [Native] Flutter should receive this app launch now")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ [Native] Error sending app launch to child_tracking: ${e.message}")
                }
            }
            Log.d(TAG, "")
        } catch (e: Exception) {
            Log.e(TAG, "❌ [Native] Error notifying app change: ${e.message}")
        }
    }
    
    private fun isSystemApp(packageName: String): Boolean {
        return try {
            val packageManager = packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            (applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
        } catch (e: Exception) {
            false
        }
    }
    
    private fun checkSyncToFlutter() {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastSyncTime >= SYNC_INTERVAL_MS) {
            syncToFlutter()
            lastSyncTime = currentTime
        }
    }
    
    private fun syncToFlutter() {
        try {
            // Convert app usage map to list
            val appUsageList = appUsageMap.values.map { appData ->
                mapOf(
                    "packageName" to appData.packageName,
                    "appName" to appData.appName,
                    "usageDuration" to (appData.totalUsageTime / 1000 / 60), // Convert to minutes
                    "launchCount" to appData.launchCount,
                    "lastUsed" to appData.lastUsed,
                    "isSystemApp" to appData.isSystemApp
                )
            }
            
            // Calculate total screen time
            // Screen time = Sum of ALL apps usage time (including system apps)
            // Because screen time means total time screen was ON, regardless of which app
            val totalScreenTime = appUsageMap.values
                .filter { !it.isSystemApp } // Exclude system apps for accurate user screen time
                .sumOf { it.totalUsageTime } / 1000 / 60 // Convert milliseconds to minutes
            
            val syncData = mapOf(
                "appUsageList" to appUsageList,
                "totalScreenTime" to totalScreenTime,
                "timestamp" to System.currentTimeMillis()
            )
            
            // Send to app_usage_tracking_service channel
            AppUsageTrackingService.getMethodChannel()?.invokeMethod("onUsageStatsUpdated", syncData)
            Log.d(TAG, "✅ [Native] Synced ${appUsageList.size} apps to app_usage_tracking_service channel (Total screen time: ${totalScreenTime}min)")
            
            // Also send each app usage to child_tracking channel for Firebase upload
            Handler(Looper.getMainLooper()).post {
                for (appData in appUsageList) {
                    try {
                        val childTrackingData = mapOf(
                            "packageName" to appData["packageName"],
                            "appName" to appData["appName"],
                            "usageDuration" to appData["usageDuration"],
                            "launchCount" to appData["launchCount"],
                            "lastUsed" to appData["lastUsed"],
                            "isSystemApp" to appData["isSystemApp"]
                        )
                        AppUsageTrackingService.getChildTrackingChannel()?.invokeMethod("onAppUsageUpdated", childTrackingData)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ [Native] Error sending app usage to child_tracking: ${e.message}")
                    }
                }
                Log.d(TAG, "✅ [Native] Sent ${appUsageList.size} app usage updates to child_tracking channel")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ [Native] Error syncing to Flutter: ${e.message}")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
        stopTracking()
    }
}

