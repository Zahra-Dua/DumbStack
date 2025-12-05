package com.example.parental_control_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.util.*

class UrlAccessibilityService : AccessibilityService() {
    
    companion object {
        private const val TAG = "UrlAccessibilityService"
        private var methodChannel: MethodChannel? = null
        private var childTrackingChannel: MethodChannel? = null
        private val pendingEvents = mutableListOf<Map<String, Any>>()
        var serviceInstance: UrlAccessibilityService? = null
        private val restrictedUntilMsByPackage = mutableMapOf<String, Long>()
        private val lastEnforcedAtMsByPackage = mutableMapOf<String, Long>()
        private var globalRestrictedUntilMs: Long = 0L
        private var lastGlobalEnforcedAtMs: Long = 0L
        
        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
            flushPending()
        }
        
        fun setChildTrackingChannel(channel: MethodChannel) {
            childTrackingChannel = channel
            Log.d(TAG, "Child tracking channel set for URL events")
        }
        
        fun emitUrl(url: String, packageName: String) {
            val event = mapOf(
                "url" to url,
                "packageName" to packageName,
                "timestamp" to System.currentTimeMillis()
            )
            if (methodChannel == null) {
                Log.e(TAG, "MethodChannel null in emitUrl; queueing")
                pendingEvents.add(event)
                return
            }
            Handler(Looper.getMainLooper()).post {
                try {
                    methodChannel?.invokeMethod("onUrlDetected", event)
                } catch (e: Exception) {
                    Log.e(TAG, "emitUrl error: ${e.message}")
                }
            }
        }
        
        private fun flushPending() {
            if (methodChannel == null) return
            if (pendingEvents.isEmpty()) return
            val handler = Handler(Looper.getMainLooper())
            for (event in pendingEvents) {
                handler.post {
                    try {
                        methodChannel?.invokeMethod("onUrlDetected", event)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error flushing pending event: ${e.message}")
                    }
                }
            }
            pendingEvents.clear()
            Log.d(TAG, "Flushed pending accessibility URL events to Flutter")
        }
        
        fun setAppRestriction(packageName: String, untilMs: Long) {
            restrictedUntilMsByPackage[packageName] = untilMs
            val untilDate = java.util.Date(untilMs)
            Log.d(TAG, "🔒 RESTRICTION SET for $packageName until ${untilDate} (${untilMs}ms)")
        }
        
        fun clearAppRestriction(packageName: String) {
            restrictedUntilMsByPackage.remove(packageName)
            Log.d(TAG, "Restriction cleared for $packageName")
        }
        
        fun clearAllRestrictions() {
            restrictedUntilMsByPackage.clear()
            Log.d(TAG, "All restrictions cleared")
        }
        
        fun checkAppRestrictionImmediately(packageName: String) {
            try {
                Handler(Looper.getMainLooper()).post {
                    methodChannel?.invokeMethod("checkAppRestrictionImmediately", mapOf(
                        "packageName" to packageName
                    ))
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking app restriction immediately: ${e.message}")
            }
        }
        
        fun isRestricted(packageName: String): Boolean {
            val until = restrictedUntilMsByPackage[packageName] ?: return false
            val now = System.currentTimeMillis()
            return now < until
        }
        
        fun isGlobalRestricted(): Boolean {
            val now = System.currentTimeMillis()
            return globalRestrictedUntilMs > 0 && now < globalRestrictedUntilMs
        }
        
        fun setGlobalRestriction(untilMs: Long) {
            globalRestrictedUntilMs = untilMs
            Log.d(TAG, "Global restriction set until $untilMs")
        }
        
        fun clearGlobalRestriction() {
            globalRestrictedUntilMs = 0L
            Log.d(TAG, "Global restriction cleared")
        }
        
        fun requestLockNow() {
            try {
                serviceInstance?.performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)
            } catch (_: Exception) {}
        }
    }
    
    private var usageStatsManager: UsageStatsManager? = null
    private var lastAppPackage: String? = null
    private var appStartTime: Long = 0

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInstance = this
        Log.d(TAG, "AccessibilityService connected and ready!")
        
        // Initialize usage stats manager
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        
            // Configure service info
            val info = AccessibilityServiceInfo().apply {
                eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED or
                            AccessibilityEvent.TYPE_VIEW_FOCUSED or
                            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                            AccessibilityEvent.TYPE_VIEW_SCROLLED or
                            AccessibilityEvent.TYPE_VIEW_CLICKED or
                            AccessibilityEvent.TYPE_VIEW_TEXT_SELECTION_CHANGED
                feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
                flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                       AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                       AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
                notificationTimeout = 50
            }
        serviceInfo = info
        Log.d(TAG, "AccessibilityService configured with event types: ${info.eventTypes}")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let { handleAccessibilityEvent(it) }
    }

    private fun handleAccessibilityEvent(event: AccessibilityEvent) {
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                handleWindowStateChanged(event)
            }
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                handleWindowContentChanged(event)
            }
            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                handleViewClicked(event)
            }
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                handleTextChanged(event)
            }
            AccessibilityEvent.TYPE_VIEW_FOCUSED -> {
                handleViewFocused(event)
            }
        }
    }
    
    private fun handleViewFocused(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString()
        // When address bar is focused, try to extract URL
        if (packageName != null && isBrowserApp(packageName)) {
            val nodeInfo = event.source
            if (nodeInfo != null) {
                val className = nodeInfo.className?.toString()
                // Check if focused view is EditText (address bar)
                if (className != null && className.contains("EditText")) {
                    Log.d(TAG, "🌐 Address bar focused in $packageName, extracting URL...")
                    Handler(Looper.getMainLooper()).postDelayed({
                        extractUrlFromBrowser()
                    }, 300)
                }
                nodeInfo.recycle()
            }
        }
    }
    
    private var lastDetectedUrl: String? = null
    private var lastUrlDetectionTime: Long = 0
    private var periodicUrlCheckHandler: Handler? = null
    private var periodicUrlCheckRunnable: Runnable? = null
    
    private fun handleWindowContentChanged(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString()
        
        // Check if this is a browser and content changed (likely URL navigation)
        if (packageName != null && isBrowserApp(packageName)) {
            val currentTime = System.currentTimeMillis()
            // Throttle URL detection to avoid duplicates (max once per 2 seconds)
            if (currentTime - lastUrlDetectionTime > 2000) {
                Log.d(TAG, "🌐 Browser content changed: $packageName, extracting URL...")
                // Try multiple times with increasing delays
                Handler(Looper.getMainLooper()).postDelayed({
                    extractUrlFromBrowser()
                }, 500) // First attempt after 500ms
                Handler(Looper.getMainLooper()).postDelayed({
                    extractUrlFromBrowser()
                }, 1500) // Second attempt after 1.5s
                Handler(Looper.getMainLooper()).postDelayed({
                    extractUrlFromBrowser()
                }, 3000) // Third attempt after 3s
                lastUrlDetectionTime = currentTime
            }
        }
    }

    private fun handleWindowStateChanged(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString()
        val className = event.className?.toString()
        
        if (packageName != null && packageName != lastAppPackage) {
            // App switched
            if (lastAppPackage != null) {
                // Record previous app usage
                recordAppUsage(lastAppPackage!!, System.currentTimeMillis() - appStartTime)
            }
            
            // Start tracking new app
            lastAppPackage = packageName
            appStartTime = System.currentTimeMillis()
            
            Log.d(TAG, "App switched to: $packageName")
            
            // Send app launch event to Flutter
            sendAppLaunchEvent(packageName, className)
        }
        
        // Check if this is a browser app and try to extract URL
        if (packageName != null && isBrowserApp(packageName)) {
            Log.d(TAG, "🌐 Browser detected: $packageName, extracting URL...")
            // Try multiple times with increasing delays
            Handler(Looper.getMainLooper()).postDelayed({
                Log.d(TAG, "🌐 Attempt 1: Extracting URL from $packageName...")
                extractUrlFromBrowser()
            }, 500) // First attempt after 500ms
            Handler(Looper.getMainLooper()).postDelayed({
                Log.d(TAG, "🌐 Attempt 2: Extracting URL from $packageName...")
                extractUrlFromBrowser()
            }, 1500) // Second attempt after 1.5s
            Handler(Looper.getMainLooper()).postDelayed({
                Log.d(TAG, "🌐 Attempt 3: Extracting URL from $packageName...")
                extractUrlFromBrowser()
            }, 3000) // Third attempt after 3s
            
            // Start periodic URL checking while browser is active
            startPeriodicUrlCheck()
        } else {
            // Stop periodic check if not a browser
            stopPeriodicUrlCheck()
        }
    }
    
    private fun isBrowserApp(packageName: String): Boolean {
        val browserPackages = listOf(
            "com.android.chrome",
            "com.chrome.browser",
            "com.chrome.dev",
            "com.chrome.canary",
            "com.google.android.apps.chrome",
            "org.mozilla.firefox",
            "org.mozilla.firefox_beta",
            "com.microsoft.emmx",
            "com.opera.browser",
            "com.opera.mini.native",
            "com.brave.browser",
            "com.vivaldi.browser",
            "com.uc.browser.en",
            "com.UCMobile.intl",
            "com.duckduckgo.mobile.android",
            "com.samsung.android.sbrowser",
            "com.mi.globalbrowser",
            "com.huawei.browser",
            "com.sec.android.app.sbrowser"
        )
        return browserPackages.contains(packageName) || 
               packageName.contains("browser") || 
               packageName.contains("chrome") ||
               packageName.contains("firefox")
    }
    
    private fun extractUrlFromBrowser() {
        try {
            Log.d(TAG, "🔍 Starting URL extraction from browser...")
            val rootNode = rootInActiveWindow
            if (rootNode != null) {
                Log.d(TAG, "✅ Root node obtained, searching for URL...")
                val url = findUrlInNode(rootNode)
                Log.d(TAG, "🔍 URL search result: ${url ?: "null"}")
                
                if (url != null && url.isNotEmpty() && url != lastDetectedUrl) {
                    Log.d(TAG, "✅ URL extracted from browser: $url")
                    lastDetectedUrl = url
                    sendUrlVisitedEvent(url, "Browser Navigation", lastAppPackage)
                } else {
                    if (url == lastDetectedUrl) {
                        Log.d(TAG, "⚠️ Same URL detected, skipping duplicate: $url")
                    } else if (url == null || url.isEmpty()) {
                        Log.d(TAG, "⚠️ No URL found in browser window (package: $lastAppPackage)")
                        // Try alternative method: check window title/content
                        tryAlternativeUrlExtraction(rootNode)
                    }
                }
                rootNode.recycle()
            } else {
                Log.d(TAG, "⚠️ Root node is null - cannot extract URL")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error extracting URL from browser: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun tryAlternativeUrlExtraction(rootNode: AccessibilityNodeInfo) {
        try {
            Log.d(TAG, "🔍 Trying alternative URL extraction method...")
            // Try to find URL in window title or any visible text
            val windowTitle = rootNode.contentDescription?.toString()
            if (windowTitle != null && isUrl(windowTitle)) {
                Log.d(TAG, "✅ URL found in window title: $windowTitle")
                if (windowTitle != lastDetectedUrl) {
                    lastDetectedUrl = windowTitle
                    sendUrlVisitedEvent(windowTitle, "Browser Window Title", lastAppPackage)
                }
                return
            }
            
            // Try to find EditText nodes (address bars)
            val editTexts = mutableListOf<AccessibilityNodeInfo>()
            collectEditTextNodes(rootNode, editTexts)
            
            for (editText in editTexts) {
                val text = editText.text?.toString()
                if (text != null && isUrl(text) && text != lastDetectedUrl) {
                    Log.d(TAG, "✅ URL found in EditText: $text")
                    lastDetectedUrl = text
                    sendUrlVisitedEvent(text, "Browser Address Bar", lastAppPackage)
                    editText.recycle()
                    break
                }
                editText.recycle()
            }
            
            if (editTexts.isEmpty()) {
                Log.d(TAG, "⚠️ No EditText nodes found in browser window")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in alternative URL extraction: ${e.message}")
        }
    }
    
    private fun collectEditTextNodes(node: AccessibilityNodeInfo?, list: MutableList<AccessibilityNodeInfo>) {
        if (node == null) return
        
        try {
            val className = node.className?.toString()
            if (className != null && className.contains("EditText")) {
                list.add(AccessibilityNodeInfo.obtain(node))
            }
            
            for (i in 0 until node.childCount) {
                val child = node.getChild(i)
                if (child != null) {
                    collectEditTextNodes(child, list)
                    child.recycle()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error collecting EditText nodes: ${e.message}")
        }
    }
    
    private fun startPeriodicUrlCheck() {
        stopPeriodicUrlCheck() // Stop any existing check
        
        periodicUrlCheckHandler = Handler(Looper.getMainLooper())
        periodicUrlCheckRunnable = object : Runnable {
            override fun run() {
                if (lastAppPackage != null && isBrowserApp(lastAppPackage!!)) {
                    Log.d(TAG, "🔄 Periodic URL check for browser: $lastAppPackage")
                    extractUrlFromBrowser()
                    periodicUrlCheckHandler?.postDelayed(this, 5000) // Check every 5 seconds
                } else {
                    stopPeriodicUrlCheck()
                }
            }
        }
        periodicUrlCheckHandler?.postDelayed(periodicUrlCheckRunnable!!, 5000)
        Log.d(TAG, "✅ Started periodic URL checking")
    }
    
    private fun stopPeriodicUrlCheck() {
        periodicUrlCheckRunnable?.let {
            periodicUrlCheckHandler?.removeCallbacks(it)
        }
        periodicUrlCheckRunnable = null
        periodicUrlCheckHandler = null
        Log.d(TAG, "⏹️ Stopped periodic URL checking")
    }
    
    private fun findUrlInNode(node: AccessibilityNodeInfo?): String? {
        if (node == null) return null
        
        try {
            // Check text content
            val text = node.text?.toString()
            if (text != null && isUrl(text)) {
                return text
            }
            
            // Check content description
            val contentDesc = node.contentDescription?.toString()
            if (contentDesc != null && isUrl(contentDesc)) {
                return contentDesc
            }
            
            // Check hint text
            val hint = node.hintText?.toString()
            if (hint != null && isUrl(hint)) {
                return hint
            }
            
            // Check if this is an EditText (address bar)
            if (node.className?.toString()?.contains("EditText") == true) {
                val editTextUrl = node.text?.toString()
                if (editTextUrl != null && isUrl(editTextUrl)) {
                    return editTextUrl
                }
            }
            
            // Recursively check child nodes
            for (i in 0 until node.childCount) {
                val child = node.getChild(i)
                if (child != null) {
                    val childUrl = findUrlInNode(child)
                    if (childUrl != null && childUrl.isNotEmpty()) {
                        child.recycle()
                        return childUrl
                    }
                    child.recycle()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in findUrlInNode: ${e.message}")
        }
        
        return null
    }

    private fun handleViewClicked(event: AccessibilityEvent) {
        // Handle URL clicks and other interactions
        val nodeInfo = event.source
        if (nodeInfo != null) {
            checkForUrlClick(nodeInfo)
        }
    }

    private fun handleTextChanged(event: AccessibilityEvent) {
        // Handle text input for URL detection
        val text = event.text?.toString()
        if (text != null && isUrl(text)) {
            Log.d("UrlAccessibilityService", "URL detected: $text")
            sendUrlVisitedEvent(text, "Unknown", event.packageName?.toString())
        }
    }

    private fun checkForUrlClick(nodeInfo: AccessibilityNodeInfo) {
        // Check if the clicked element contains a URL
        val text = nodeInfo.text?.toString()
        val contentDescription = nodeInfo.contentDescription?.toString()
        
        if (text != null && isUrl(text)) {
            sendUrlVisitedEvent(text, "Click", nodeInfo.packageName?.toString())
        } else if (contentDescription != null && isUrl(contentDescription)) {
            sendUrlVisitedEvent(contentDescription, "Click", nodeInfo.packageName?.toString())
        }
        
        // Recursively check child nodes
        for (i in 0 until nodeInfo.childCount) {
            val child = nodeInfo.getChild(i)
            if (child != null) {
                checkForUrlClick(child)
                child.recycle()
            }
        }
    }

    private fun isUrl(text: String): Boolean {
        if (text.isEmpty() || text.length < 4) return false
        
        // Check for http/https URLs
        if (text.contains("http://") || text.contains("https://")) {
            return true
        }
        
        // Check for common URL patterns
        val urlPattern = Regex(
            "(www\\.)?[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.[a-zA-Z]{2,}(/.*)?",
            RegexOption.IGNORE_CASE
        )
        if (urlPattern.containsMatchIn(text)) {
            return true
        }
        
        // Check for common TLDs
        val tlds = listOf(".com", ".org", ".net", ".edu", ".gov", ".io", ".co", ".in", ".pk", ".uk")
        for (tld in tlds) {
            if (text.contains(tld, ignoreCase = true)) {
                // Make sure it's not just a word containing the TLD
                val parts = text.split(tld)
                if (parts.size > 1 && parts[0].isNotEmpty()) {
                    return true
                }
            }
        }
        
        return false
    }

    private fun recordAppUsage(packageName: String, duration: Long) {
        // Skip excluded system apps
        if (shouldExcludeApp(packageName)) {
            Log.d(TAG, "⏭️ Skipping excluded system app: $packageName")
            return
        }
        
        Log.d(TAG, "📱 App usage: $packageName for ${duration}ms")
        
        val appUsageData = mapOf(
            "packageName" to packageName,
            "appName" to getAppName(packageName),
            "usageDuration" to (duration / 1000 / 60).toInt(), // Convert to minutes
            "launchCount" to 1,
            "lastUsed" to System.currentTimeMillis(),
            "isSystemApp" to isSystemApp(packageName)
        )
        
        // Send app usage data to Flutter via child_tracking channel
        Handler(Looper.getMainLooper()).post {
            try {
                childTrackingChannel?.invokeMethod("onAppUsageUpdated", appUsageData)
                Log.d(TAG, "✅ App usage sent to child_tracking channel: $packageName")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error sending app usage to child_tracking: ${e.message}")
            }
        }
    }
    
    private fun getAppName(packageName: String): String {
        return try {
            val pm = applicationContext.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }
    
    private fun isSystemApp(packageName: String): Boolean {
        return try {
            val pm = applicationContext.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
        } catch (e: Exception) {
            false
        }
    }
    
    private fun shouldExcludeApp(packageName: String): Boolean {
        // List of system apps to exclude from tracking
        val excludedPackages = setOf(
            "com.google.android.inputmethod.latin", // Gboard
            "com.android.inputmethod.latin", // Android Keyboard
            "com.android.systemui", // System UI
            "com.android.launcher", // Launcher
            "com.android.launcher2", // Launcher 2
            "com.android.launcher3", // Launcher 3
            "com.google.android.launcher", // Google Launcher
            "com.miui.home", // MIUI Launcher
            "com.huawei.android.launcher", // Huawei Launcher
            "com.samsung.android.launcher", // Samsung Launcher
            "com.oneplus.launcher", // OnePlus Launcher
            "com.oppo.launcher", // Oppo Launcher
            "com.vivo.launcher", // Vivo Launcher
            "com.realme.launcher", // Realme Launcher
            "com.transsion.launcher", // Transsion Launcher (Infinix/Tecno)
            "com.android.settings", // Settings
            "com.android.keychain", // Keychain
            "android", // Android system
            "com.android.phone", // Phone app
            "com.android.dialer", // Dialer
            "com.android.contacts", // Contacts
            "com.android.mms", // Messages
            "com.android.providers.settings", // Settings Provider
            "com.android.providers.contacts", // Contacts Provider
            "com.android.providers.telephony", // Telephony Provider
            "com.android.providers.downloads", // Downloads Provider
            "com.android.providers.media", // Media Provider
            "com.android.providers.calendar", // Calendar Provider
            "com.android.providers.downloads.ui", // Downloads UI
            "com.android.documentsui", // Documents UI
            "com.android.packageinstaller", // Package Installer
            "com.android.packageinstaller2", // Package Installer 2
            "com.android.vending", // Play Store (optional, can include if needed)
        )
        
        // Exclude if it's in the excluded list or is a system app
        return excludedPackages.contains(packageName) || isSystemApp(packageName)
    }

    private fun sendAppLaunchEvent(packageName: String, className: String?) {
        // Skip excluded system apps
        if (shouldExcludeApp(packageName)) {
            Log.d(TAG, "⏭️ Skipping excluded system app launch: $packageName")
            return
        }
        
        Log.d(TAG, "🚀 App launched: $packageName")
        
        val launchData = mapOf(
            "packageName" to packageName,
            "appName" to getAppName(packageName),
            "className" to (className ?: ""),
            "appId" to packageName,
            "usageDuration" to 0,
            "launchCount" to 1,
            "timestamp" to System.currentTimeMillis()
        )
        
        Handler(Looper.getMainLooper()).post {
            try {
                childTrackingChannel?.invokeMethod("onAppLaunched", launchData)
                Log.d(TAG, "✅ App launch sent to child_tracking channel: $packageName")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error sending app launch to child_tracking: ${e.message}")
            }
        }
    }

    private fun sendUrlVisitedEvent(url: String, source: String, packageName: String?) {
        // Normalize URL - ensure it has http:// or https://
        val normalizedUrl = normalizeUrl(url)
        
        Log.d(TAG, "🌐 URL visited detected: $normalizedUrl in $packageName")
        
        val eventData = mapOf(
            "url" to normalizedUrl,
            "title" to extractTitleFromUrl(normalizedUrl),
            "packageName" to (packageName ?: "Unknown"),
            "browserName" to getBrowserName(packageName),
            "metadata" to mapOf(
                "source" to source,
                "timestamp" to System.currentTimeMillis()
            )
        )
        
        Handler(Looper.getMainLooper()).post {
            // Send to child_tracking channel for Firebase upload
            try {
                childTrackingChannel?.invokeMethod("onUrlVisited", eventData)
                Log.d(TAG, "✅ URL event sent to child_tracking channel: $normalizedUrl")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error sending URL to child_tracking: ${e.message}")
            }
            
            // Also send to url_tracking channel for UI updates (if needed)
            try {
                methodChannel?.invokeMethod("onUrlDetected", eventData)
            } catch (e: Exception) {
                Log.e(TAG, "Error sending URL to url_tracking: ${e.message}")
            }
        }
    }
    
    private fun normalizeUrl(url: String): String {
        var normalized = url.trim()
        
        // Remove whitespace and newlines
        normalized = normalized.replace("\n", "").replace("\r", "")
        
        // If URL already has protocol, return as is
        if (normalized.startsWith("http://") || normalized.startsWith("https://")) {
            return normalized
        }
        
        // If URL starts with www., add https://
        if (normalized.startsWith("www.")) {
            return "https://$normalized"
        }
        
        // If URL contains a TLD, add https://
        if (isUrl(normalized) && !normalized.startsWith("http")) {
            return "https://$normalized"
        }
        
        return normalized
    }
    
    private fun extractTitleFromUrl(url: String): String {
        return try {
            // Try to extract domain name as title
            val uri = android.net.Uri.parse(url)
            val host = uri.host ?: url
            if (host.startsWith("www.")) {
                host.substring(4)
            } else {
                host
            }
        } catch (e: Exception) {
            url
        }
    }

    private fun getBrowserName(packageName: String?): String {
        return when (packageName) {
            "com.android.chrome" -> "Chrome"
            "org.mozilla.firefox" -> "Firefox"
            "com.microsoft.emmx" -> "Edge"
            "com.opera.browser" -> "Opera"
            "com.sec.android.app.sbrowser" -> "Samsung Browser"
            else -> "Unknown Browser"
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "AccessibilityService interrupted")
        stopPeriodicUrlCheck()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopPeriodicUrlCheck()
        Log.d(TAG, "AccessibilityService destroyed")
        serviceInstance = null
    }
}
