import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visited_url.dart';
import '../models/browser_info.dart';
import 'local_storage_service.dart';
import 'firebase_sync_service.dart';
import 'safe_browsing_checker.dart';
import '../../data/config/safe_browsing_api_config.dart';

class UrlTrackingService {
  // Singleton pattern to ensure a single shared instance across the app
  static final UrlTrackingService _instance = UrlTrackingService._internal();
  factory UrlTrackingService() => _instance;
  UrlTrackingService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  static const MethodChannel _channel = MethodChannel('url_tracking');
  Timer? _trackingTimer;
  final StreamController<VisitedUrl> _urlController = 
      StreamController<VisitedUrl>.broadcast(sync: true);
  
  Stream<VisitedUrl> get urlStream => _urlController.stream;
  
  bool _isTracking = false;
  bool _isProcessingUrl = false; // Prevent multiple URL processing
  int _processedUrlsCount = 0; // Track how many URLs processed
  DateTime? _lastCheckTime;
  final Set<String> _recentUrls = <String>{}; // Track recent URLs to prevent duplicates
  final Queue<_PendingUrl> _pendingQueue = Queue<_PendingUrl>();
  final LocalStorageService _localStorage = LocalStorageService();
  
  // Public getter for local storage access
  LocalStorageService get localStorage => _localStorage;
  final FirebaseSyncService _firebase = const FirebaseSyncService(enabled: false);
  // Safe Browsing API key from config
  final SafeBrowsingChecker _gsb = SafeBrowsingChecker(apiKey: SafeBrowsingApiConfig.apiKey);

  // Default constructor redirects to singleton factory
  UrlTrackingService.init();

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    print('📞 UrlTrackingService: Method call received: ${call.method}');
    print('📞 UrlTrackingService: Arguments: ${call.arguments}');
    switch (call.method) {
      case 'onUrlDetected':
        final String url = call.arguments['url'] as String;
        final String packageName = call.arguments['packageName'] as String;
        print('📞 UrlTrackingService: Processing URL from Android: $url from $packageName');
        print('📞 UrlTrackingService: Is processing flag: $_isProcessingUrl');
        await receiveUrlFromAccessibilityService(url, packageName);
        break;
      case 'onDomainDetected':
        final String domain = call.arguments as String;
        print('📞 UrlTrackingService: Domain detected via VPN: $domain');
        // Normalize to https domain form
        final normalized = domain.startsWith('http') ? domain : 'https://$domain';
        await receiveUrlFromAccessibilityService(normalized, 'vpn');
        break;
      case 'onBrowserPulse':
        // Browser in foreground but no URL yet -> temporarily suspend VPN domains
        final String pkg = call.arguments['packageName'] as String? ?? '';
        print('📞 UrlTrackingService: Browser pulse from $pkg');
        // Record pulse time; used in foreground filter to require recent pulse
        _lastCheckTime = DateTime.now();
        break;
      default:
        print('📞 UrlTrackingService: Unknown method call: ${call.method}');
    }
  }

  // Method to receive URLs from AccessibilityService - ONLY REAL URLS
  Future<void> receiveUrlFromAccessibilityService(String url, String packageName) async {
    print('🔍 UrlTrackingService: Received URL from AccessibilityService: $url from $packageName');
    print('🔍 UrlTrackingService: URL length: ${url.length}');
    print('🔍 UrlTrackingService: Package: $packageName');
    print('🧠 Tracking active state at URL receive: $_isTracking');
    
    // Process only when live tracking is active
    if (!_isTracking) {
      print('⚠️ UrlTrackingService: Tracking not active, enabling inline to accept early URL.');
      _isTracking = true; // allow early arrivals
    }
    
    // Enqueue and drain sequentially to avoid drops and races
    _pendingQueue.add(_PendingUrl(url: url, packageName: packageName));
    _drainQueue();
  }

  Future<void> _drainQueue() async {
    if (_isProcessingUrl) {
      // If already processing, schedule next attempt
      Future.delayed(const Duration(milliseconds: 100), () => _drainQueue());
      return;
    }
    _isProcessingUrl = true;
    try {
      while (_pendingQueue.isNotEmpty) {
        final pending = _pendingQueue.removeFirst();
        final rawUrl = pending.url;
        final pkg = pending.packageName;
        
        if (!isRealVisitedUrl(rawUrl)) {
          print('❌ UrlTrackingService: Rejected invalid URL (queue): $rawUrl');
          continue;
        }
        
        // Only list exact URLs coming from real browsers; skip VPN/DNS domain candidates
        if (pkg == 'vpn' || pkg == 'dns') {
          print('🚫 UrlTrackingService: Skipping non-browser domain candidate from $pkg: $rawUrl');
          continue;
        }
        
        // Foreground filter: only accept if browser/webview likely active
        final fg = await _getForegroundPackage();
        final pulseOk = _lastCheckTime != null && DateTime.now().difference(_lastCheckTime!).inSeconds <= 2;
        if (fg != null && fg.isNotEmpty) {
          final allowed = fg.contains('chrome') || fg.contains('browser') || fg.contains('firefox') || fg.contains('emmx') || fg.contains('opera') || fg.contains('samsung');
          if (!allowed && pending.packageName == 'vpn') {
            print('🚫 Skipping domain because foreground not a browser: $fg');
            continue;
          }
          if (pending.packageName == 'vpn' && !pulseOk) {
            print('🛑 Skipping domain (no recent browser pulse)');
            continue;
          }
        }

        final normalizedUrl = _normalizeUrl(rawUrl);
        print('✅ UrlTrackingService: Valid URL detected: $normalizedUrl');
        
        final now = DateTime.now();
        final urlKey = '${pkg}_$normalizedUrl';
        if (_recentUrls.contains(urlKey)) {
          print('⏳ UrlTrackingService: URL visited recently, skipping: $normalizedUrl');
          continue;
        }
        
        // FAST PROCESSING - Add URL immediately to stream
        print('🚀 FAST PROCESSING: Adding URL immediately to list');
        
        final browserName = _getBrowserName(pkg);
        var visitedUrl = VisitedUrl(
          id: '${pkg}_${now.millisecondsSinceEpoch}',
          url: normalizedUrl,
          title: _getUrlTitle(normalizedUrl, browserName),
          visitedAt: now,
          packageName: pkg,
        );
        
        print('📝 UrlTrackingService: Created VisitedUrl: ${visitedUrl.url} - ${visitedUrl.title}');
        // Safe Browsing check
        try {
          final threats = await _gsb.checkUrl(normalizedUrl);
          if (threats.isNotEmpty) {
            // reuse isBlocked for flagged and encode threats in title suffix
            final flaggedTitle = '${visitedUrl.title} (FLAGGED)';
            visitedUrl = visitedUrl.copyWith(isBlocked: true, title: flaggedTitle);
          }
        } catch (_) {}

        // IMMEDIATE STREAM - Add to UI instantly
        _urlController.add(visitedUrl);
        print('✨ UrlTrackingService: URL added to stream IMMEDIATELY: ${visitedUrl.url}');
        
        // PERSIST TO LOCAL STORAGE - Save for proper list maintenance
        try {
          await _localStorage.addVisitedUrl(visitedUrl);
          print('💾 LocalStorage: URL saved to storage: ${visitedUrl.url}');
        } catch (e) {
          print('⚠️ LocalStorage: Error saving URL: $e');
        }
        
        _processedUrlsCount++;
        print('📊 Total URLs processed: $_processedUrlsCount');
        
        _recentUrls.add(urlKey);
        Timer(const Duration(milliseconds: 200), () {
          _recentUrls.remove(urlKey);
        });
      }
    } catch (e) {
      print('❌ Error draining queue: $e');
    } finally {
      _isProcessingUrl = false;
      if (_pendingQueue.isNotEmpty) {
        Future.microtask(() => _drainQueue());
      }
      print('🔄 UrlTrackingService: Processing flag reset');
    }
  }

  // URL validation - ONLY accept real URLs that were actually visited
  bool isRealVisitedUrl(String url) {
    if (url.isEmpty || url.length < 7) {
      print('❌ URL validation: Empty or too short URL');
      return false;
    }
    
    // ULTRA STRICT: Only accept proper web URLs
    final validUrlPatterns = [
      // Any http/https URL
      RegExp(r'^https?://[^\s]+$', caseSensitive: false),
      // www.+ fallback
      RegExp(r'^www\.[^\s]+$', caseSensitive: false),
      // Scheme-less domain with optional path/query/fragment
      RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[^\s]*)?$', caseSensitive: false),
    ];
    
    // Check if URL matches valid patterns
    for (final pattern in validUrlPatterns) {
      if (pattern.hasMatch(url)) {
        // Additional validation: must have proper domain structure
        if (url.contains('.') && 
            !url.contains('chrome://') && 
            !url.contains('about:') &&
            !url.contains('file://') &&
            !url.contains('data:') &&
            !url.contains('javascript:') &&
            !url.contains('mailto:') &&
            !url.contains('tel:') &&
            !url.contains('sms:') &&
            !url.contains('content://') &&
            !url.contains('android-app://') &&
            !url.contains('intent://') &&
            !url.contains('market://') &&
            !url.contains('play://')) {
          print('✅ URL validation: Valid web URL: $url');
          return true;
        }
      }
    }
    
    print('❌ URL validation: No valid pattern matched: $url');
    return false;
  }

  String _normalizeUrl(String url) {
    // Preserve URL exactly as seen in the address bar (no stripping of params)
    return url.trim();
  }

  // REMOVED: _saveUrlToStorage method - NO STORAGE SAVING

  Future<List<VisitedUrl>> loadVisitedUrls() async {
    try {
      // Load URLs from local storage
      final storedUrls = await _localStorage.getVisitedUrls();
      print('📊 LocalStorage: Loaded ${storedUrls.length} URLs from storage');
      return storedUrls;
    } catch (e) {
      print('❌ Error loading URLs from storage: $e');
      return [];
    }
  }

  // REMOVED: _saveCleanedUrls method - NO STORAGE SAVING

  Future<void> startTracking() async {
    if (_isTracking) {
      print('⚠️ Tracking already started');
      return;
    }
    
    print('🚀 Starting URL tracking...');
    _isTracking = true;
    _lastCheckTime = DateTime.now().subtract(const Duration(minutes: 1));
    
    // CLEAR ALL OLD DATA ON START
    _recentUrls.clear();
    _processedUrlsCount = 0;
    _pendingQueue.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tracking_enabled', true);
      await prefs.remove('visited_urls'); // Clear old URLs from preferences
      print('🗑️ Cleared all old data from preferences');
    } catch (_) {}
    
    // CLEAN START - No old data
    
    // Request permissions and check status
    print('🔐 Requesting permissions...');
    await requestAccessibilityPermission();
    await requestUsageStatsPermission();
    
    // Check permission status
    final hasAccessibility = await hasAccessibilityPermission();
    final hasUsageStats = await hasUsageStatsPermission();
    print('🔐 Permission status - Accessibility: $hasAccessibility, Usage Stats: $hasUsageStats');
    
    if (!hasAccessibility && !hasUsageStats) {
      print('⚠️ No permissions granted - URL tracking may not work properly');
    }
    
    print('✅ URL tracking started - only real URLs from AccessibilityService will be tracked');
  }

  Future<void> stopTracking() async {
    print('🛑 Stopping URL tracking...');
    _isTracking = false;
    _trackingTimer?.cancel();
    _trackingTimer = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tracking_enabled', false);
    } catch (_) {}
  }

  // REMOVED: All storage methods - NO STORAGE OPERATIONS

  String _getBrowserName(String packageName) {
    switch (packageName) {
      case BrowserPackages.chrome:
        return 'Chrome';
      case BrowserPackages.firefox:
        return 'Firefox';
      case BrowserPackages.edge:
        return 'Edge';
      case BrowserPackages.opera:
        return 'Opera';
      case BrowserPackages.samsungBrowser:
        return 'Samsung Internet';
      case BrowserPackages.ucBrowser:
        return 'UC Browser';
      case BrowserPackages.brave:
        return 'Brave';
      default:
        return 'Browser';
    }
  }

  String _getUrlTitle(String url, String browserName) {
    try {
      final uri = Uri.parse(url);
      final domain = uri.host;
      
      if (domain.isEmpty) return url;
      
      // Remove 'www.' prefix if present
      final cleanDomain = domain.startsWith('www.') 
          ? domain.substring(4) 
          : domain;
      
      // Extract site name from domain
      final parts = cleanDomain.split('.');
      if (parts.isNotEmpty) {
        final siteName = parts[0];
        
        // Capitalize first letter
        final capitalizedSiteName = siteName.isNotEmpty 
            ? '${siteName[0].toUpperCase()}${siteName.substring(1)}'
            : cleanDomain;
        
        return capitalizedSiteName;
      }
      
      return cleanDomain;
    } catch (e) {
      return url;
    }
  }

  // Permission methods
  Future<bool> hasUsageStatsPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('hasUsageStatsPermission');
        return result as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasAccessibilityPermission() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('hasAccessibilityPermission');
        return result as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestAccessibilityPermission() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('requestAccessibilityPermission');
      }
    } catch (e) {
      throw Exception('Failed to request accessibility permission: $e');
    }
  }

  Future<void> requestUsageStatsPermission() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('requestUsageStatsPermission');
      }
    } catch (e) {
      throw Exception('Failed to request usage stats permission: $e');
    }
  }

  // Test URL detection - send a test URL to Flutter
  Future<void> testUrlDetection() async {
    try {
      if (Platform.isAndroid) {
        print('🧪 Testing URL detection...');
        await _channel.invokeMethod('testUrlDetection');
        print('✅ Test URL detection called');
      }
    } catch (e) {
      print('❌ Error testing URL detection: $e');
    }
  }

  // VPN blocking methods (keeping existing implementation)
  Future<void> startVpnBlocking() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('startVpnBlocking');
        print('VPN blocking started');
      }
    } catch (e) {
      throw Exception('Failed to start VPN blocking: $e');
    }
  }

  Future<void> stopVpnBlocking() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('stopVpnBlocking');
        print('VPN blocking stopped');
      }
    } catch (e) {
      throw Exception('Failed to stop VPN blocking: $e');
    }
  }

  Future<void> addBlockedDomain(String domain) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('addBlockedDomain', {'domain': domain});
        print('Added blocked domain: $domain');
      }
    } catch (e) {
      throw Exception('Failed to add blocked domain: $e');
    }
  }

  Future<void> removeBlockedDomain(String domain) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('removeBlockedDomain', {'domain': domain});
        print('Removed blocked domain: $domain');
      }
    } catch (e) {
      throw Exception('Failed to remove blocked domain: $e');
    }
  }

  Future<List<String>> getBlockedDomains() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('getBlockedDomains');
        return List<String>.from(result);
      }
      return [];
    } catch (e) {
      print('Failed to get blocked domains: $e');
      return [];
    }
  }

  // REMOVED: clearDummyUrls - NO STORAGE OPERATIONS

  // REMOVED: All storage methods - NO STORAGE OPERATIONS

  // Start fresh - only track new visits from now
  Future<void> startFreshTracking() async {
    try {
      // CLEAR ALL CACHE AND OLD DATA
      _recentUrls.clear();
      _processedUrlsCount = 0; // Reset counter
      _pendingQueue.clear(); // Clear pending queue
      _lastCheckTime = null; // Reset last check time
      
      // Clear local storage cache
      try {
        await _localStorage.clearAllUrls();
        print('🗑️ Cleared all local storage URLs');
      } catch (e) {
        print('⚠️ Error clearing local storage: $e');
      }
      
      print('🔄 Started fresh tracking - ALL OLD DATA CLEARED, only new visits will be tracked');
      
    } catch (e) {
      print('❌ Error starting fresh tracking: $e');
    }
  }

  // Test method to manually add a URL for debugging
  Future<void> testAddUrl(String testUrl) async {
    print('🧪 Testing URL addition: $testUrl');
    await receiveUrlFromAccessibilityService(testUrl, 'com.android.chrome');
  }

  Future<String?> _getForegroundPackage() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('getForegroundPackage');
        return result as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Test method to simulate receiving URL from accessibility service
  Future<void> testReceiveUrlFromAccessibilityService(String url, String packageName) async {
    print('🧪 Testing receiveUrlFromAccessibilityService with: $url from $packageName');
    await receiveUrlFromAccessibilityService(url, packageName);
  }

  // Debug method to check service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    return {
      'isTracking': _isTracking,
      'hasAccessibilityPermission': await hasAccessibilityPermission(),
      'hasUsageStatsPermission': await hasUsageStatsPermission(),
      'recentUrlsCount': _recentUrls.length,
      'processedUrlsCount': _processedUrlsCount,
      'lastCheckTime': _lastCheckTime?.toIso8601String(),
    };
  }

  // Test method to trigger Android-side URL detection test
  Future<void> testAndroidUrlDetection() async {
    try {
      if (Platform.isAndroid) {
        print('🧪 Triggering Android URL detection test...');
        await _channel.invokeMethod('testUrlDetection');
        print('🧪 Android URL detection test triggered');
      }
    } catch (e) {
      print('❌ Error testing Android URL detection: $e');
    }
  }

  // Test method to verify method channel communication
  Future<void> testMethodChannel() async {
    try {
      print('🧪 Testing method channel communication...');
      // Test with a simple URL
      await receiveUrlFromAccessibilityService('https://www.google.com', 'com.android.chrome');
      print('🧪 Method channel test completed');
    } catch (e) {
      print('❌ Error testing method channel: $e');
    }
  }

  void dispose() {
    stopTracking();
    _urlController.close();
  }
}

class _PendingUrl {
  final String url;
  final String packageName;
  _PendingUrl({required this.url, required this.packageName});
}