import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../url_tracking/data/services/url_tracking_firebase_service.dart';
import '../../../app_limits/data/services/app_usage_firebase_service.dart';

class RealDataCollectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UrlTrackingFirebaseService _urlService = UrlTrackingFirebaseService();
  final AppUsageFirebaseService _appService = AppUsageFirebaseService();
  final MethodChannel _channel = MethodChannel('child_tracking');

  // Initialize real data collection
  Future<void> initializeRealDataCollection({
    required String childId,
    required String parentId,
  }) async {
    try {
      print('🚀 Starting real data collection for child: $childId, parent: $parentId');
      
      // Set up method channel for native communication
      _channel.setMethodCallHandler((call) async {
        print('📨 [ChildTracking] Method channel received: ${call.method}');
        print('📨 [ChildTracking] Arguments: ${call.arguments}');
        
        switch (call.method) {
          case 'onUrlVisited':
            print('🌐 [ChildTracking] Handling onUrlVisited event...');
            await _handleRealUrlVisited(call.arguments, childId, parentId);
            break;
          case 'onAppUsageUpdated':
            print('📱 [ChildTracking] Handling onAppUsageUpdated event...');
            await _handleRealAppUsage(call.arguments, childId, parentId);
            break;
          case 'onAppLaunched':
            print('🚀 [ChildTracking] Handling onAppLaunched event...');
            await _handleRealAppLaunched(call.arguments, childId, parentId);
            break;
          default:
            print('⚠️ [ChildTracking] Unknown method: ${call.method}');
        }
      });

      // Start native tracking services
      await _startNativeTracking();
      
      print('✅ Real data collection initialized successfully');
      print('📊 Listening for events on child_tracking channel...');
    } catch (e) {
      print('❌ Error initializing real data collection: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Start native Android tracking services
  Future<void> _startNativeTracking() async {
    try {
      print('🔄 [ChildTracking] Starting native Android tracking services...');
      
      // Check accessibility permission first (required for URL tracking)
      try {
        final hasAccessibility = await _channel.invokeMethod<bool>('checkAccessibilityPermission') ?? false;
        if (hasAccessibility) {
          print('✅ [ChildTracking] Accessibility permission: GRANTED');
        } else {
          print('⚠️ [ChildTracking] Accessibility permission: NOT GRANTED');
          print('⚠️ [ChildTracking] URL tracking will not work without accessibility permission');
          print('⚠️ [ChildTracking] Please enable it in Settings > Accessibility');
        }
      } catch (e) {
        print('⚠️ [ChildTracking] Could not check accessibility permission: $e');
      }
      
      // Start URL tracking service
      print('🌐 [ChildTracking] Starting URL tracking service...');
      try {
        await _channel.invokeMethod('startUrlTracking');
        print('✅ [ChildTracking] URL tracking service started');
        print('📊 [ChildTracking] Listening for URL visits in browsers...');
      } catch (e) {
        print('❌ [ChildTracking] Failed to start URL tracking: $e');
        print('⚠️ [ChildTracking] Make sure accessibility permission is granted');
      }
      
      // Check usage stats permission (required for app tracking)
      try {
        final hasUsageStats = await _channel.invokeMethod<bool>('checkUsageStatsPermission') ?? false;
        if (hasUsageStats) {
          print('✅ [ChildTracking] Usage stats permission: GRANTED');
        } else {
          print('⚠️ [ChildTracking] Usage stats permission: NOT GRANTED');
          print('⚠️ [ChildTracking] App tracking will not work without usage stats permission');
        }
      } catch (e) {
        print('⚠️ [ChildTracking] Could not check usage stats permission: $e');
      }
      
      // Start app usage tracking service
      print('📱 [ChildTracking] Starting app usage tracking service...');
      try {
        await _channel.invokeMethod('startAppUsageTracking');
        print('✅ [ChildTracking] App usage tracking service started');
        print('📊 [ChildTracking] Listening for app launches and usage...');
      } catch (e) {
        print('❌ [ChildTracking] Failed to start app usage tracking: $e');
        print('⚠️ [ChildTracking] Make sure usage stats permission is granted');
      }
      
      print('✅ [ChildTracking] All native tracking services started');
      print('📊 [ChildTracking] Now listening for URL visits and app usage...');
    } catch (e) {
      print('❌ [ChildTracking] Error starting native tracking: $e');
      print('❌ [ChildTracking] Stack trace: ${StackTrace.current}');
    }
  }

  // Handle real URL visited from native side
  Future<void> _handleRealUrlVisited(
    Map<dynamic, dynamic> data,
    String childId,
    String parentId,
  ) async {
    try {
      print('');
      print('🌐 ========== 🌐 URL VISITED - CHILD SIDE 🌐 ==========');
      print('🌐 URL: ${data['url']}');
      print('🌐 Title: ${data['title'] ?? 'No title'}');
      print('🌐 Package: ${data['packageName'] ?? 'Unknown'}');
      print('🌐 Browser: ${data['browserName'] ?? 'Unknown'}');
      print('🌐 Child ID: $childId');
      print('🌐 Parent ID: $parentId');
      print('🌐 Timestamp: ${DateTime.now()}');
      print('🌐 ====================================================');
      
      if (data['url'] == null || (data['url'] as String).isEmpty) {
        print('⚠️ [URL Tracking] URL is empty, skipping upload');
        return;
      }
      
      await _urlService.uploadUrlToFirebase(
        url: data['url'] ?? '',
        title: data['title'] ?? '',
        packageName: data['packageName'] ?? '',
        childId: childId,
        parentId: parentId,
        browserName: data['browserName'],
        metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
      );
      
      print('✅ [URL Tracking] URL uploaded to Firebase successfully!');
      print('✅ [URL Tracking] Firebase path: parents/$parentId/children/$childId/visitedUrls');
      print('✅ [URL Tracking] Parent side should now see this URL');
      print('');
    } catch (e) {
      print('❌ [URL Tracking] Error uploading URL: $e');
      print('❌ [URL Tracking] Stack trace: ${StackTrace.current}');
    }
  }

  // Handle real app usage from native side
  Future<void> _handleRealAppUsage(
    Map<dynamic, dynamic> data,
    String childId,
    String parentId,
  ) async {
    try {
      final appName = data['appName'] ?? 'Unknown App';
      final packageName = data['packageName'] ?? 'Unknown';
      final usageDuration = data['usageDuration'] ?? 0;
      final launchCount = data['launchCount'] ?? 0;
      
      print('');
      print('📱 ========== 📱 APP USAGE - CHILD SIDE 📱 ==========');
      print('📱 App Name: $appName');
      print('📱 Package: $packageName');
      print('📱 Usage Duration: ${usageDuration} minutes');
      print('📱 Launch Count: $launchCount');
      print('📱 Child ID: $childId');
      print('📱 Parent ID: $parentId');
      print('📱 Timestamp: ${DateTime.now()}');
      print('📱 =================================================');
      
      await _appService.uploadAppUsageToFirebase(
        packageName: packageName,
        appName: appName,
        usageDuration: usageDuration,
        launchCount: launchCount,
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
      
      print('✅ [App Tracking] App usage uploaded to Firebase successfully!');
      print('✅ [App Tracking] Firebase path: parents/$parentId/children/$childId/appUsage');
      print('✅ [App Tracking] Parent side should now see this app usage');
      print('');
    } catch (e) {
      print('❌ [App Tracking] Error uploading app usage: $e');
      print('❌ [App Tracking] Stack trace: ${StackTrace.current}');
    }
  }

  // Handle real app launched from native side
  Future<void> _handleRealAppLaunched(
    Map<dynamic, dynamic> data,
    String childId,
    String parentId,
  ) async {
    try {
      final appName = data['appName'] ?? 'Unknown App';
      final packageName = data['packageName'] ?? 'Unknown';
      final usageDuration = data['usageDuration'] ?? 0;
      final launchCount = data['launchCount'] ?? 1; // Default to 1 if not provided
      
      print('');
      print('🚀 ========== 🚀 APP LAUNCHED - CHILD SIDE 🚀 ==========');
      print('🚀 App Name: $appName');
      print('🚀 Package: $packageName');
      print('🚀 Usage Duration: $usageDuration minutes');
      print('🚀 Launch Count: $launchCount');
      print('🚀 Child ID: $childId');
      print('🚀 Parent ID: $parentId');
      print('🚀 Timestamp: ${DateTime.now()}');
      print('🚀 ====================================================');
      
      // Use uploadAppUsageToFirebase instead of updateAppUsageInFirebase
      // This will create a new document if it doesn't exist, or update if it does
      await _appService.uploadAppUsageToFirebase(
        packageName: packageName,
        appName: appName,
        usageDuration: usageDuration,
        launchCount: launchCount,
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
      
      print('✅ [App Tracking] App launch uploaded to Firebase successfully!');
      print('✅ [App Tracking] Firebase path: parents/$parentId/children/$childId/appUsage');
      print('✅ [App Tracking] Parent side should now see this app launch');
      print('');
    } catch (e) {
      print('❌ [App Tracking] Error uploading app launch: $e');
      print('❌ [App Tracking] Stack trace: ${StackTrace.current}');
    }
  }

  // Simulate real data collection for testing (remove this in production)
  Future<void> simulateRealDataCollection({
    required String childId,
    required String parentId,
  }) async {
    try {
      print('🧪 Simulating real data collection...');
      
      // Simulate real URLs
      final realUrls = [
        {
          'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'title': 'Rick Astley - Never Gonna Give You Up',
          'packageName': 'com.google.android.youtube',
          'browserName': 'Chrome',
          'visitedAt': DateTime.now().subtract(Duration(minutes: 5)),
        },
        {
          'url': 'https://www.facebook.com',
          'title': 'Facebook',
          'packageName': 'com.facebook.katana',
          'browserName': 'Facebook App',
          'visitedAt': DateTime.now().subtract(Duration(minutes: 10)),
        },
        {
          'url': 'https://www.instagram.com',
          'title': 'Instagram',
          'packageName': 'com.instagram.android',
          'browserName': 'Instagram App',
          'visitedAt': DateTime.now().subtract(Duration(minutes: 15)),
        },
      ];

      // Simulate real app usage
      final realApps = [
        {
          'packageName': 'com.google.android.youtube',
          'appName': 'YouTube',
          'usageDuration': 45, // minutes
          'launchCount': 3,
          'lastUsed': DateTime.now().subtract(Duration(minutes: 2)),
          'appIcon': 'https://play-lh.googleusercontent.com/...',
          'isSystemApp': false,
          'riskScore': 0.2,
        },
        {
          'packageName': 'com.facebook.katana',
          'appName': 'Facebook',
          'usageDuration': 30,
          'launchCount': 2,
          'lastUsed': DateTime.now().subtract(Duration(minutes: 8)),
          'appIcon': 'https://play-lh.googleusercontent.com/...',
          'isSystemApp': false,
          'riskScore': 0.3,
        },
        {
          'packageName': 'com.instagram.android',
          'appName': 'Instagram',
          'usageDuration': 25,
          'launchCount': 4,
          'lastUsed': DateTime.now().subtract(Duration(minutes: 12)),
          'appIcon': 'https://play-lh.googleusercontent.com/...',
          'isSystemApp': false,
          'riskScore': 0.1,
        },
      ];

      // Upload simulated real URLs
      for (final urlData in realUrls) {
        await _urlService.uploadUrlToFirebase(
          url: urlData['url'] as String,
          title: urlData['title'] as String,
          packageName: urlData['packageName'] as String,
          childId: childId,
          parentId: parentId,
          browserName: urlData['browserName'] as String,
          metadata: {
            'simulated': true,
            'visitedAt': urlData['visitedAt'],
          },
        );
      }

      // Upload simulated real app usage
      for (final appData in realApps) {
        await _appService.uploadAppUsageToFirebase(
          packageName: appData['packageName'] as String,
          appName: appData['appName'] as String,
          usageDuration: appData['usageDuration'] as int,
          launchCount: appData['launchCount'] as int,
          lastUsed: appData['lastUsed'] as DateTime,
          childId: childId,
          parentId: parentId,
          appIcon: appData['appIcon'] as String,
          metadata: {
            'simulated': true,
            'riskScore': appData['riskScore'],
          },
          isSystemApp: appData['isSystemApp'] as bool,
          riskScore: appData['riskScore'] as double,
        );
      }

      print('✅ Simulated real data uploaded to Firebase');
    } catch (e) {
      print('❌ Error simulating real data: $e');
    }
  }

  // Stop real data collection
  Future<void> stopRealDataCollection() async {
    try {
      await _channel.invokeMethod('stopAllTracking');
      _channel.setMethodCallHandler(null);
      print('✅ Real data collection stopped');
    } catch (e) {
      print('❌ Error stopping real data collection: $e');
    }
  }
}
