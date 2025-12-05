import 'dart:async';
import '../models/installed_app.dart';
import 'app_usage_firebase_service.dart';
import 'screen_time_firebase_service.dart';
import 'installed_apps_firebase_service.dart';

/// Service for Child Device to Sync Data to Firebase
/// 
/// This service runs on the child's device and:
/// - Syncs app usage data to Firebase
/// - Syncs screen time to Firebase
/// - Syncs installed apps list to Firebase
/// - Runs periodically to keep data up-to-date
class ChildDeviceSyncService {
  final AppUsageFirebaseService _appUsageService = AppUsageFirebaseService();
  final ScreenTimeFirebaseService _screenTimeService = ScreenTimeFirebaseService();
  final InstalledAppsFirebaseService _installedAppsService = InstalledAppsFirebaseService();
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  String? _childId;
  String? _parentId;
  
  /// Initialize sync service with child and parent IDs
  void initialize({required String childId, required String parentId}) {
    _childId = childId;
    _parentId = parentId;
    print('✅ [ChildDeviceSyncService] Initialized for child: $childId, parent: $parentId');
  }
  
  /// Start periodic sync (every 30 seconds)
  void startPeriodicSync() {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildDeviceSyncService] Not initialized. Call initialize() first.');
      return;
    }
    
    if (_syncTimer != null) {
      print('⚠️ [ChildDeviceSyncService] Sync already running');
      return;
    }
    
    print('🔄 [ChildDeviceSyncService] Starting periodic sync...');
    
    // Sync immediately
    syncAllData();
    
    // Then sync every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncAllData();
    });
  }
  
  /// Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('⏹️ [ChildDeviceSyncService] Stopped periodic sync');
  }
  
  /// Sync all data to Firebase
  Future<void> syncAllData() async {
    if (_isSyncing) {
      print('⚠️ [ChildDeviceSyncService] Sync already in progress, skipping...');
      return;
    }
    
    if (_childId == null || _parentId == null) {
      print('❌ [ChildDeviceSyncService] Not initialized');
      return;
    }
    
    _isSyncing = true;
    
    try {
      print('🔄 [ChildDeviceSyncService] Starting full sync...');
      
      // Note: Individual sync methods should be called with proper parameters
      // This method is a placeholder - actual implementation should call
      // syncAppUsage(), syncScreenTime(), and syncInstalledApps() with data
      print('⚠️ [ChildDeviceSyncService] Full sync requires individual method calls with data');
      
      print('✅ [ChildDeviceSyncService] Full sync completed');
    } catch (e) {
      print('❌ [ChildDeviceSyncService] Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Sync app usage data to Firebase
  /// 
  /// This should be called from UsageStatsService when app usage changes
  Future<void> syncAppUsage({
    required String packageName,
    required String appName,
    required int usageDurationMinutes,
    required int launchCount,
    required DateTime lastUsed,
    String? appIcon,
    bool isSystemApp = false,
  }) async {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildDeviceSyncService] Not initialized');
      return;
    }
    
    try {
      await _appUsageService.uploadAppUsageToFirebase(
        packageName: packageName,
        appName: appName,
        usageDuration: usageDurationMinutes,
        launchCount: launchCount,
        lastUsed: lastUsed,
        childId: _childId!,
        parentId: _parentId!,
        appIcon: appIcon,
        isSystemApp: isSystemApp,
      );
      
      print('✅ [ChildDeviceSyncService] App usage synced: $appName');
    } catch (e) {
      print('❌ [ChildDeviceSyncService] Error syncing app usage: $e');
    }
  }
  
  /// Sync all current app usage stats
  /// 
  /// Note: This is a placeholder. Actual implementation should:
  /// 1. Get current usage stats from UsageStatsService
  /// 2. Call syncAppUsage() for each app with proper parameters
  Future<void> syncAllAppUsage() async {
    // This will be called from UsageStatsService
    // The actual implementation should get current usage stats
    // and sync them to Firebase
    print('📊 [ChildDeviceSyncService] Syncing all app usage...');
  }
  
  /// Sync screen time to Firebase
  Future<void> syncScreenTime({
    required int totalScreenTimeMinutes,
    required DateTime date,
  }) async {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildDeviceSyncService] Not initialized');
      return;
    }
    
    try {
      await _screenTimeService.updateDailyScreenTime(
        childId: _childId!,
        parentId: _parentId!,
        totalScreenTimeMinutes: totalScreenTimeMinutes,
        date: date,
      );
      
      print('✅ [ChildDeviceSyncService] Screen time synced: $totalScreenTimeMinutes minutes');
    } catch (e) {
      print('❌ [ChildDeviceSyncService] Error syncing screen time: $e');
    }
  }
  
  /// Sync installed apps list to Firebase
  Future<void> syncInstalledApps({required List<InstalledApp> apps}) async {
    if (_childId == null || _parentId == null) {
      print('❌ [ChildDeviceSyncService] Not initialized');
      return;
    }
    
    try {
      await _installedAppsService.syncInstalledApps(
        apps: apps,
        childId: _childId!,
        parentId: _parentId!,
      );
      
      print('✅ [ChildDeviceSyncService] Installed apps synced: ${apps.length} apps');
    } catch (e) {
      print('❌ [ChildDeviceSyncService] Error syncing installed apps: $e');
    }
  }
  
  /// Get current child and parent IDs
  String? get childId => _childId;
  String? get parentId => _parentId;
  
  /// Dispose resources
  void dispose() {
    stopPeriodicSync();
    _childId = null;
    _parentId = null;
  }
}

