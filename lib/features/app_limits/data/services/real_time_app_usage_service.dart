import 'dart:async';
import 'package:flutter/services.dart';
import 'child_device_sync_service.dart';
import 'child_limits_sync_service.dart';
import '../datasources/app_list_service.dart';
import '../datasources/usage_stats_service.dart';
import '../models/installed_app.dart';

/// Real-time App Usage Tracking Service (Flutter Side)
/// 
/// This service:
/// - Listens to native Android app usage events
/// - Syncs app usage data to Firebase in real-time
/// - Tracks screen time
/// - Handles app launch/change events
class RealTimeAppUsageService {
  static const MethodChannel _channel = MethodChannel('app_usage_tracking_service');
  
  final ChildDeviceSyncService _syncService = ChildDeviceSyncService();
  final ChildLimitsSyncService _limitsSyncService = ChildLimitsSyncService();
  final AppListService _appListService = AppListService();
  final UsageStatsService _usageStatsService = UsageStatsService();
  
  bool _isTracking = false;
  String? _childId;
  String? _parentId;
  
  // Current app usage data
  final Map<String, AppUsageData> _appUsageMap = {};
  int _totalScreenTimeMinutes = 0;
  
  // Timer for periodic installed apps sync
  Timer? _installedAppsSyncTimer;
  
  /// Initialize service with child and parent IDs
  void initialize({
    required String childId,
    required String parentId,
  }) {
    _childId = childId;
    _parentId = parentId;
    
    // Initialize sync service
    _syncService.initialize(childId: childId, parentId: parentId);
    
    // Initialize limits sync service
    _limitsSyncService.initialize(childId: childId, parentId: parentId);
    
    // Set up method channel handler
    _channel.setMethodCallHandler(_handleMethodCall);
    
    print('✅ [RealTimeAppUsageService] Initialized for child: $childId');
  }
  
  /// Start real-time tracking
  Future<void> startTracking() async {
    if (_isTracking) {
      print('⚠️ [RealTimeAppUsageService] Already tracking');
      // Even if already tracking, ensure installed apps sync is running
      if (_installedAppsSyncTimer == null) {
        print('🔄 [RealTimeAppUsageService] Starting installed apps sync (was missing)');
        _startInstalledAppsSync();
      }
      return;
    }
    
    if (_childId == null || _parentId == null) {
      print('❌ [RealTimeAppUsageService] Not initialized. Call initialize() first.');
      print('   childId: $_childId, parentId: $_parentId');
      return;
    }
    
    // CRITICAL: Start installed apps sync FIRST, even before native service
    // This ensures data is synced even if native service fails
    print('🔄 [RealTimeAppUsageService] Starting installed apps sync FIRST...');
    _startInstalledAppsSync();
    
    // Start Firebase limits sync to local storage
    print('🔄 [RealTimeAppUsageService] Starting Firebase limits sync...');
    _limitsSyncService.startSyncing();
    
    try {
      // Start native Android service (for app usage tracking)
      print('🔄 [RealTimeAppUsageService] Starting native Android service...');
      await _channel.invokeMethod('startTracking');
      
      _isTracking = true;
      print('✅ [RealTimeAppUsageService] Started real-time tracking');
      
      // Start periodic sync to Firebase (for app usage data)
      _syncService.startPeriodicSync();
      
    } catch (e) {
      print('❌ [RealTimeAppUsageService] Error starting native tracking: $e');
      print('⚠️ [RealTimeAppUsageService] Native service failed, but installed apps sync will continue');
      // Don't set _isTracking = true if native service fails
      // But installed apps sync is already started above, so it will continue
    }
  }
  
  /// Stop real-time tracking
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return;
    }
    
    try {
      // Stop native Android service
      await _channel.invokeMethod('stopTracking');
      
      _isTracking = false;
      print('⏹️ [RealTimeAppUsageService] Stopped tracking');
      
      // Final sync before stopping
      await syncAllToFirebase();
      
      // Stop periodic sync
      _syncService.stopPeriodicSync();
      
      // Stop installed apps sync
      _stopInstalledAppsSync();
      
      // Stop limits sync
      _limitsSyncService.stopSyncing();
    } catch (e) {
      print('❌ [RealTimeAppUsageService] Error stopping tracking: $e');
    }
  }
  
  /// Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onAppChanged':
          await _handleAppChanged(call.arguments);
          break;
          
        case 'onUsageStatsUpdated':
          await _handleUsageStatsUpdated(call.arguments);
          break;
          
        default:
          print('⚠️ [RealTimeAppUsageService] Unknown method: ${call.method}');
      }
    } catch (e) {
      print('❌ [RealTimeAppUsageService] Error handling method call: $e');
    }
  }
  
  /// Handle app changed event from native
  Future<void> _handleAppChanged(Map<dynamic, dynamic> data) async {
    try {
      final packageName = data['packageName'] as String?;
      final appName = data['appName'] as String?;
      final isSystemApp = data['isSystemApp'] as bool? ?? false;
      
      if (packageName == null) return;
      
      print('📱 [RealTimeAppUsageService] App changed: $appName ($packageName)');
      
      // Update app usage map
      _appUsageMap.putIfAbsent(packageName, () => AppUsageData(
        packageName: packageName,
        appName: appName ?? packageName,
        isSystemApp: isSystemApp,
      ));
      
      // Increment launch count
      _appUsageMap[packageName]!.launchCount++;
      _appUsageMap[packageName]!.lastUsed = DateTime.now();
      
      // CRITICAL: Check app limit immediately when app changes
      print('🔒 [RealTimeAppUsageService] Checking app limit for: $packageName');
      await _usageStatsService.checkAppRestrictionImmediately(packageName);
      
    } catch (e) {
      print('❌ [RealTimeAppUsageService] Error handling app changed: $e');
    }
  }
  
  /// Handle usage stats updated from native
  Future<void> _handleUsageStatsUpdated(Map<dynamic, dynamic> data) async {
    try {
      final appUsageList = data['appUsageList'] as List<dynamic>?;
      final totalScreenTime = data['totalScreenTime'] as int? ?? 0;
      
      if (appUsageList == null) return;
      
      print('📊 [RealTimeAppUsageService] Usage stats updated: ${appUsageList.length} apps, ${totalScreenTime}min total');
      
      // Update local data
      _totalScreenTimeMinutes = totalScreenTime;
      
      // Update app usage map
      for (var appData in appUsageList) {
        final packageName = appData['packageName'] as String?;
        if (packageName == null) continue;
        
        _appUsageMap.putIfAbsent(packageName, () => AppUsageData(
          packageName: packageName,
          appName: appData['appName'] as String? ?? packageName,
          isSystemApp: appData['isSystemApp'] as bool? ?? false,
        ));
        
        final appUsage = _appUsageMap[packageName]!;
        appUsage.usageDurationMinutes = appData['usageDuration'] as int? ?? 0;
        appUsage.launchCount = appData['launchCount'] as int? ?? 0;
        appUsage.lastUsed = DateTime.fromMillisecondsSinceEpoch(
          appData['lastUsed'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        );
      }
      
      // Sync to Firebase
      await syncAllToFirebase();
      
    } catch (e) {
      print('❌ [RealTimeAppUsageService] Error handling usage stats updated: $e');
    }
  }
  
  /// Sync all app usage data to Firebase
  Future<void> syncAllToFirebase() async {
    if (_childId == null || _parentId == null) {
      print('❌ [RealTimeAppUsageService] Not initialized');
      return;
    }
    
    try {
      print('🔄 [RealTimeAppUsageService] Syncing ${_appUsageMap.length} apps to Firebase...');
      
      // Sync each app usage
      for (var appUsage in _appUsageMap.values) {
        await _syncService.syncAppUsage(
          packageName: appUsage.packageName,
          appName: appUsage.appName,
          usageDurationMinutes: appUsage.usageDurationMinutes,
          launchCount: appUsage.launchCount,
          lastUsed: appUsage.lastUsed,
          isSystemApp: appUsage.isSystemApp,
        );
      }
      
      // Sync total screen time
      // Screen time = Total time child used phone today (sum of all app usage times)
      // Exclude system apps for accurate user screen time
      final userAppsTotalTime = _appUsageMap.values
          .where((app) => !app.isSystemApp)
          .fold<int>(0, (sum, app) => sum + app.usageDurationMinutes);
      
      await _syncService.syncScreenTime(
        totalScreenTimeMinutes: userAppsTotalTime > 0 ? userAppsTotalTime : _totalScreenTimeMinutes,
        date: DateTime.now(),
      );
      
      print('📊 [RealTimeAppUsageService] Screen time synced: ${userAppsTotalTime > 0 ? userAppsTotalTime : _totalScreenTimeMinutes} minutes');
      
      print('✅ [RealTimeAppUsageService] Synced to Firebase successfully');
    } catch (e) {
      print('❌ [RealTimeAppUsageService] Error syncing to Firebase: $e');
    }
  }
  
  /// Start periodic sync of installed apps (ALL apps, not just used ones)
  void _startInstalledAppsSync() {
    if (_childId == null || _parentId == null) {
      print('❌ [RealTimeAppUsageService] Not initialized for installed apps sync');
      print('   childId: $_childId, parentId: $_parentId');
      return;
    }
    
    print('🔄 [RealTimeAppUsageService] Starting installed apps sync...');
    print('   Child ID: $_childId');
    print('   Parent ID: $_parentId');
    
    // Sync immediately (don't wait) - CRITICAL for first sync
    print('🔄 [RealTimeAppUsageService] Triggering IMMEDIATE sync...');
    _syncInstalledApps().then((_) {
      print('✅ [RealTimeAppUsageService] Initial installed apps sync completed successfully');
    }).catchError((e, stackTrace) {
      print('❌ [RealTimeAppUsageService] Initial sync failed: $e');
      print('❌ Stack trace: $stackTrace');
      // Retry after 10 seconds
      print('🔄 [RealTimeAppUsageService] Retrying sync in 10 seconds...');
      Future.delayed(const Duration(seconds: 10), () {
        _syncInstalledApps();
      });
    });
    
    // Then sync every 2 minutes (reduced from 5 for faster updates)
    _installedAppsSyncTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      print('🔄 [RealTimeAppUsageService] Periodic sync triggered (every 2 minutes)');
      _syncInstalledApps();
    });
    
    print('✅ [RealTimeAppUsageService] Started periodic installed apps sync (every 2 minutes)');
  }
  
  /// Stop periodic sync of installed apps
  void _stopInstalledAppsSync() {
    _installedAppsSyncTimer?.cancel();
    _installedAppsSyncTimer = null;
    print('⏹️ [RealTimeAppUsageService] Stopped installed apps sync');
  }
  
  /// Sync ALL installed apps to Firebase (used + unused)
  Future<void> _syncInstalledApps() async {
    if (_childId == null || _parentId == null) {
      print('❌ [RealTimeAppUsageService] ========== SYNC FAILED ==========');
      print('❌ [RealTimeAppUsageService] Cannot sync: childId or parentId is null');
      print('   childId: $_childId');
      print('   parentId: $_parentId');
      print('❌ [RealTimeAppUsageService] ==================================');
      return;
    }
    
    try {
      print('🔄 [RealTimeAppUsageService] ========== SYNCING INSTALLED APPS ==========');
      print('   Child ID: $_childId');
      print('   Parent ID: $_parentId');
      print('   Timestamp: ${DateTime.now().toIso8601String()}');
      
      // Get ALL installed apps from device (not just used ones)
      print('📱 [RealTimeAppUsageService] Step 1: Getting installed apps from device...');
      final syncStartTime = DateTime.now();
      
      final List<InstalledApp> allInstalledApps = await _appListService.getInstalledApps();
      
      final fetchDuration = DateTime.now().difference(syncStartTime);
      print('📱 [RealTimeAppUsageService] Step 1 Complete: Found ${allInstalledApps.length} installed apps');
      print('📱 [RealTimeAppUsageService] ⏱️ Fetch time: ${fetchDuration.inMilliseconds}ms');
      
      if (allInstalledApps.isEmpty) {
        print('⚠️ [RealTimeAppUsageService] ⚠️⚠️⚠️ CRITICAL: NO APPS FOUND ON DEVICE! ⚠️⚠️⚠️');
        print('⚠️ [RealTimeAppUsageService] Possible reasons:');
        print('   1. QUERY_ALL_PACKAGES permission not granted');
        print('   2. device_apps package not working');
        print('   3. Device compatibility issue');
        print('⚠️ [RealTimeAppUsageService] ============================================');
        return;
      }
      
      // Count apps by type
      final userApps = allInstalledApps.where((app) => !app.isSystemApp).length;
      final systemApps = allInstalledApps.where((app) => app.isSystemApp).length;
      print('📱 [RealTimeAppUsageService] App breakdown:');
      print('   - Total: ${allInstalledApps.length}');
      print('   - User Apps: $userApps');
      print('   - System Apps: $systemApps');
      
      // Print first 10 apps for debugging
      print('📱 [RealTimeAppUsageService] Sample apps (first 10):');
      for (var i = 0; i < (allInstalledApps.length > 10 ? 10 : allInstalledApps.length); i++) {
        final app = allInstalledApps[i];
        print('   ${i + 1}. ${app.appName} (${app.packageName}) [${app.isSystemApp ? "System" : "User"}]');
      }
      
      // Sync to Firebase
      print('🔄 [RealTimeAppUsageService] Step 2: Syncing to Firebase...');
      print('   Firebase path: parents/$_parentId/children/$_childId/installedApps');
      
      final firebaseStartTime = DateTime.now();
      await _syncService.syncInstalledApps(apps: allInstalledApps);
      final firebaseDuration = DateTime.now().difference(firebaseStartTime);
      
      print('✅ [RealTimeAppUsageService] Step 2 Complete: Synced to Firebase');
      print('📱 [RealTimeAppUsageService] ⏱️ Firebase sync time: ${firebaseDuration.inMilliseconds}ms');
      print('✅ [RealTimeAppUsageService] Successfully synced ${allInstalledApps.length} installed apps to Firebase');
      print('   Firebase path: parents/$_parentId/children/$_childId/installedApps');
      print('🔄 [RealTimeAppUsageService] ============================================');
    } catch (e, stackTrace) {
      print('❌ [RealTimeAppUsageService] ========== SYNC ERROR ==========');
      print('❌ [RealTimeAppUsageService] Error: $e');
      print('❌ [RealTimeAppUsageService] Stack trace: $stackTrace');
      print('❌ [RealTimeAppUsageService] ================================');
    }
  }
  
  /// Public method to manually trigger installed apps sync
  Future<void> syncInstalledAppsNow() async {
    print('🔄 [RealTimeAppUsageService] Manual sync triggered');
    await _syncInstalledApps();
  }
  
  /// Get current app usage data
  Map<String, AppUsageData> get appUsageMap => Map.unmodifiable(_appUsageMap);
  
  /// Get total screen time
  int get totalScreenTimeMinutes => _totalScreenTimeMinutes;
  
  /// Dispose resources
  void dispose() {
    stopTracking();
    _stopInstalledAppsSync();
    _limitsSyncService.dispose();
    _appUsageMap.clear();
    _childId = null;
    _parentId = null;
  }
}

/// App Usage Data Model
class AppUsageData {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  int usageDurationMinutes;
  int launchCount;
  DateTime lastUsed;
  
  AppUsageData({
    required this.packageName,
    required this.appName,
    this.isSystemApp = false,
    this.usageDurationMinutes = 0,
    this.launchCount = 0,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();
}

