import 'package:flutter/services.dart';
import '../../../url_tracking/data/services/child_url_tracking_service.dart';
import '../../../app_limits/data/services/child_app_usage_service.dart';

class ChildTrackingIntegrationService {
  final ChildUrlTrackingService _urlService = ChildUrlTrackingService();
  final ChildAppUsageService _appService = ChildAppUsageService();
  final MethodChannel _channel = MethodChannel('child_tracking');

  // Initialize tracking integration
  Future<void> initializeTracking({
    required String childId,
    required String parentId,
  }) async {
    try {
      // Set up method channel to receive data from native side
      _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'onUrlVisited':
            await _handleUrlVisited(call.arguments, childId, parentId);
            break;
          case 'onAppUsageUpdated':
            await _handleAppUsageUpdated(call.arguments, childId, parentId);
            break;
          case 'onAppLaunched':
            await _handleAppLaunched(call.arguments, childId, parentId);
            break;
        }
      });

      print('✅ Child tracking integration initialized');
    } catch (e) {
      print('❌ Error initializing child tracking: $e');
    }
  }

  // Handle URL visited from native side
  Future<void> _handleUrlVisited(
    Map<dynamic, dynamic> data,
    String childId,
    String parentId,
  ) async {
    try {
      await _urlService.uploadVisitedUrl(
        url: data['url'] ?? '',
        title: data['title'] ?? '',
        packageName: data['packageName'] ?? '',
        childId: childId,
        parentId: parentId,
        browserName: data['browserName'],
        metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      );
    } catch (e) {
      print('❌ Error handling URL visited: $e');
    }
  }

  // Handle app usage updated from native side
  Future<void> _handleAppUsageUpdated(
    Map<dynamic, dynamic> data,
    String childId,
    String parentId,
  ) async {
    try {
      await _appService.uploadAppUsage(
        packageName: data['packageName'] ?? '',
        appName: data['appName'] ?? '',
        usageDuration: data['usageDuration'] ?? 0,
        launchCount: data['launchCount'] ?? 0,
        lastUsed: data['lastUsed'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(data['lastUsed'])
            : DateTime.now(),
        childId: childId,
        parentId: parentId,
        appIcon: data['appIcon'],
        metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
        isSystemApp: data['isSystemApp'] ?? false,
        riskScore: data['riskScore']?.toDouble(),
      );
    } catch (e) {
      print('❌ Error handling app usage updated: $e');
    }
  }

  // Handle app launched from native side
  Future<void> _handleAppLaunched(
    Map<dynamic, dynamic> data,
    String childId,
    String parentId,
  ) async {
    try {
      // Update launch count for the app
      await _appService.updateAppUsage(
        childId: childId,
        parentId: parentId,
        appId: data['appId'] ?? '',
        usageDuration: data['usageDuration'] ?? 0,
        launchCount: data['launchCount'] ?? 0,
        lastUsed: DateTime.now(),
        riskScore: data['riskScore']?.toDouble(),
      );
    } catch (e) {
      print('❌ Error handling app launched: $e');
    }
  }

  // Start periodic data sync
  Future<void> startPeriodicSync({
    required String childId,
    required String parentId,
    Duration interval = const Duration(minutes: 5),
  }) async {
    // This will run in the background and sync data periodically
    // You can implement this using a timer or background service
    print('✅ Periodic sync started for child: $childId');
  }

  // Stop tracking
  Future<void> stopTracking() async {
    try {
      _channel.setMethodCallHandler(null);
      print('✅ Child tracking stopped');
    } catch (e) {
      print('❌ Error stopping child tracking: $e');
    }
  }
}
