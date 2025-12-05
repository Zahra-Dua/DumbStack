import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'message_permission_service.dart';
import 'child_message_monitor_service.dart';
import '../datasources/message_remote_datasource.dart';
import '../../../location_tracking/data/services/geofencing_detection_service.dart';
import '../../../location_tracking/data/datasources/geofence_remote_datasource.dart';
import '../../../app_limits/data/services/real_time_app_usage_service.dart';
import '../../../app_limits/data/datasources/usage_stats_service.dart';
import '../../../call_logging/data/datasources/call_log_remote_datasource.dart';
import '../../../url_blocking/data/services/child_vpn_blocking_service.dart';

class ChildAppInitializationService {
  static const bool _vpnBlockingEnabled = false;
  final MessageRemoteDataSourceImpl _messageDataSource;
  ChildMessageMonitorService? _messageMonitor;
  GeofencingDetectionService? _geofencingService;
  RealTimeAppUsageService? _realTimeAppUsageService;
  CallLogRemoteDataSourceImpl? _callLogDataSource;
  ChildVpnBlockingService? _vpnBlockingService;

  ChildAppInitializationService({required MessageRemoteDataSourceImpl messageDataSource})
      : _messageDataSource = messageDataSource;

  /// Initialize child app with all permissions and services
  Future<void> initializeChildApp() async {
    try {
      print('Initializing child app...');
      
      // Get parent and child IDs from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('parent_uid');
      final childId = prefs.getString('child_uid');

      if (parentId == null || childId == null) {
        print('Parent or child ID not found in SharedPreferences');
        return;
      }

      print('Child app initialized for: $childId, parent: $parentId');

      // Request all permissions at startup
      await _requestAllPermissions();

      // Initialize message monitoring
      await _initializeMessageMonitoring(parentId, childId);

      // Initialize geofencing monitoring
      await _initializeGeofencingMonitoring();

      // Initialize real-time app usage tracking (includes installed apps sync)
      await _initializeAppUsageTracking(parentId, childId);

      // Initialize call log monitoring (uploads calls to Firebase)
      await _initializeCallLogMonitoring(parentId, childId);

      if (_vpnBlockingEnabled) {
        // Initialize VPN-based URL blocking
        await _initializeVpnBlocking();
      } else {
        print('⚠️ [ChildAppInit] VPN-based URL blocking is currently disabled.');
      }

      print('Child app initialization completed');
    } catch (e) {
      print('Error initializing child app: $e');
    }
  }

  /// Request all necessary permissions
  Future<void> _requestAllPermissions() async {
    try {
      print('🔐 [ChildAppInit] Requesting all permissions...');
      
      // Request message permissions
      final messagePermissionsGranted = await MessagePermissionService.requestMessagePermissions();
      if (!messagePermissionsGranted) {
        print('⚠️ [ChildAppInit] Message permissions not granted');
      } else {
        print('✅ [ChildAppInit] Message permissions granted');
      }

      // Request call log permissions (required for suspicious call detection)
      try {
        final phonePermission = await Permission.phone.request();
        final contactsPermission = await Permission.contacts.request();
        
        if (phonePermission.isGranted && contactsPermission.isGranted) {
          print('✅ [ChildAppInit] Call log and contacts permissions granted');
        } else {
          print('⚠️ [ChildAppInit] Call log or contacts permissions not granted');
          print('   Phone permission: $phonePermission');
          print('   Contacts permission: $contactsPermission');
        }
      } catch (e) {
        print('⚠️ [ChildAppInit] Error requesting call log permissions: $e');
      }
      
      print('✅ [ChildAppInit] All permissions requested');
    } catch (e) {
      print('❌ [ChildAppInit] Error requesting permissions: $e');
    }
  }

  /// Initialize message monitoring
  Future<void> _initializeMessageMonitoring(String parentId, String childId) async {
    try {
      print('Initializing message monitoring...');
      
      _messageMonitor = ChildMessageMonitorService(dataSource: _messageDataSource);
      await _messageMonitor!.initialize();
      
      print('Message monitoring initialized');
    } catch (e) {
      print('Error initializing message monitoring: $e');
    }
  }

  /// Initialize geofencing monitoring
  Future<void> _initializeGeofencingMonitoring() async {
    try {
      print('Initializing geofencing monitoring...');
      
      final geofenceDataSource = GeofenceRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      );
      
      _geofencingService = GeofencingDetectionService(
        geofenceDataSource: geofenceDataSource,
      );
      
      await _geofencingService!.startGeofencingMonitoring();
      
      print('Geofencing monitoring initialized');
    } catch (e) {
      print('Error initializing geofencing monitoring: $e');
    }
  }

  /// Initialize app usage tracking and installed apps sync
  Future<void> _initializeAppUsageTracking(String parentId, String childId) async {
    try {
      print('🔄 [ChildAppInit] ========== INITIALIZING APP USAGE TRACKING ==========');
      print('   Child ID: $childId');
      print('   Parent ID: $parentId');
      
      _realTimeAppUsageService = RealTimeAppUsageService();
      
      // Initialize service with child and parent IDs
      print('🔄 [ChildAppInit] Initializing RealTimeAppUsageService...');
      _realTimeAppUsageService!.initialize(
        childId: childId,
        parentId: parentId,
      );
      print('✅ [ChildAppInit] Service initialized');
      
      // Start real-time tracking (this also starts installed apps sync)
      print('🔄 [ChildAppInit] Starting tracking service...');
      await _realTimeAppUsageService!.startTracking();
      
      // Also start UsageStatsService real-time monitoring
      print('🔄 [ChildAppInit] Starting UsageStatsService real-time monitoring...');
      final usageStatsService = UsageStatsService();
      await usageStatsService.startMonitoring();
      print('✅ [ChildAppInit] UsageStatsService real-time monitoring started');
      
      print('✅ [ChildAppInit] App usage tracking and installed apps sync initialized');
      print('📱 [ChildAppInit] Installed apps will sync immediately and then every 2 minutes');
      print('🔄 [ChildAppInit] Real-time app monitoring active (every 2 seconds)');
      print('📊 [ChildAppInit] Usage stats syncing to Firebase every 30 seconds');
      print('🔄 [ChildAppInit] ====================================================');
    } catch (e, stackTrace) {
      print('❌ [ChildAppInit] Error initializing app usage tracking: $e');
      print('❌ [ChildAppInit] Stack trace: $stackTrace');
    }
  }


  /// Initialize call log monitoring (uploads calls to Firebase)
  Future<void> _initializeCallLogMonitoring(String parentId, String childId) async {
    try {
      print('🚀 [ChildAppInit] Initializing call log monitoring...');
      
      _callLogDataSource = CallLogRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
      );
      
      // Start continuous monitoring (checks every 5 minutes and uploads new calls)
      _callLogDataSource!.startContinuousMonitoring(
        parentId: parentId,
        childId: childId,
      );
      
      print('✅ [ChildAppInit] Call log monitoring initialized');
      print('📞 [ChildAppInit] Calls will be uploaded to Firebase every 5 minutes');
      print('📞 [ChildAppInit] First upload will happen immediately');
    } catch (e) {
      print('❌ [ChildAppInit] Error initializing call log monitoring: $e');
    }
  }

  /// Stop all services
  Future<void> stopAllServices() async {
    try {
      print('Stopping all services...');
      
      // Stop message monitoring
      _messageMonitor?.stop();
      _messageMonitor = null;
      
      // Stop geofencing monitoring
      await _geofencingService?.stopGeofencingMonitoring();
      _geofencingService = null;
      
      // Stop app usage tracking
      await _realTimeAppUsageService?.stopTracking();
      _realTimeAppUsageService?.dispose();
      _realTimeAppUsageService = null;
      
      // Stop call log monitoring
      _callLogDataSource?.stopMonitoring();
      _callLogDataSource = null;
      
      // Stop VPN blocking
      await _vpnBlockingService?.stopVpn();
      _vpnBlockingService?.dispose();
      _vpnBlockingService = null;
      
      print('All services stopped');
    } catch (e) {
      print('Error stopping services: $e');
    }
  }

  /// Check if all permissions are granted
  Future<bool> checkAllPermissions() async {
    try {
      final messagePermissions = await MessagePermissionService.checkMessagePermissions();
      // TODO: Add other permission checks
      
      return messagePermissions; // && other permissions
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  /// Get permission status for display
  Future<Map<String, bool>> getPermissionStatus() async {
    return await MessagePermissionService.getPermissionStatus();
  }

  /// Dispose resources
  void dispose() {
    _messageMonitor?.stop();
    _messageMonitor = null;
    _geofencingService?.dispose();
    _geofencingService = null;
    _realTimeAppUsageService?.dispose();
    _realTimeAppUsageService = null;
      _vpnBlockingService?.dispose();
      _vpnBlockingService = null;
    }

  /// Initialize VPN-based URL blocking
  Future<void> _initializeVpnBlocking() async {
    if (!_vpnBlockingEnabled) {
      print('ℹ️ [ChildAppInit] VPN blocking skipped (disabled flag).');
      return;
    }
    try {
      print('🚀 [ChildAppInit] Initializing VPN-based URL blocking...');
      
      _vpnBlockingService = ChildVpnBlockingService();
      await _vpnBlockingService!.initialize();
      
      print('✅ [ChildAppInit] VPN-based URL blocking initialized');
      print('🔒 [ChildAppInit] Blocked URLs will be enforced system-wide via DNS blocking');
    } catch (e) {
      print('❌ [ChildAppInit] Error initializing VPN blocking: $e');
    }
  }
}
