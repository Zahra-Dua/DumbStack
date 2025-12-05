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
        print('📨 Method channel received: ${call.method}');
        print('📨 Arguments: ${call.arguments}');
        
        switch (call.method) {
          case 'onUrlVisited':
            print('🌐 Handling onUrlVisited event...');
            await _handleRealUrlVisited(call.arguments, childId, parentId);
            break;
          case 'onAppUsageUpdated':
            print('📱 Handling onAppUsageUpdated event...');
            await _handleRealAppUsage(call.arguments, childId, parentId);
            break;
          case 'onAppLaunched':
            print('🚀 Handling onAppLaunched event...');
            await _handleRealAppLaunched(call.arguments, childId, parentId);
            break;
          default:
            print('⚠️ Unknown method: ${call.method}');
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
      // Start URL tracking service
      await _channel.invokeMethod('startUrlTracking');
      
      // Start app usage tracking service
      await _channel.invokeMethod('startAppUsageTracking');
      
      print('✅ Native tracking services started');
    } catch (e) {
      print('❌ Error starting native tracking: $e');
    }
  }

  // Handle real URL visited from native side
  Future<void> _handleRealUrlVisited(
    Map<dynamic, dynamic> data,
    String childId,
    String parentId,
  ) async {
    try {
      print('🌐 ========== URL VISITED EVENT ==========');
      print('🌐 URL: ${data['url']}');
      print('🌐 Title: ${data['title']}');
      print('🌐 Package: ${data['packageName']}');
      print('🌐 Browser: ${data['browserName']}');
      print('🌐 Child ID: $childId');
      print('🌐 Parent ID: $parentId');
      print('🌐 =======================================');
      
      if (data['url'] == null || (data['url'] as String).isEmpty) {
        print('⚠️ URL is empty, skipping upload');
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
      
      print('✅ Real URL uploaded to Firebase successfully: ${data['url']}');
      print('✅ Firebase path: parents/$parentId/children/$childId/visitedUrls');
    } catch (e) {
      print('❌ Error uploading real URL: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Handle real app usage from native side
  Future<void> _handleRealAppUsage(
    Map<dynamic, dynamic> data,
    String childId,
    String parentId,
  ) async {
    try {
      print('📱 Real app usage: ${data['appName']}');
      
      await _appService.uploadAppUsageToFirebase(
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
      
      print('✅ Real app usage uploaded to Firebase: ${data['appName']}');
    } catch (e) {
      print('❌ Error uploading real app usage: $e');
    }
  }

  // Handle real app launched from native side
  Future<void> _handleRealAppLaunched(
    Map<dynamic, dynamic> data,
    String childId,
    String parentId,
  ) async {
    try {
      print('🚀 Real app launched: ${data['appName']}');
      
      await _appService.updateAppUsageInFirebase(
        childId: childId,
        parentId: parentId,
        appId: data['appId'] ?? '',
        usageDuration: data['usageDuration'] ?? 0,
        launchCount: data['launchCount'] ?? 0,
        lastUsed: DateTime.now(),
        riskScore: data['riskScore']?.toDouble(),
      );
      
      print('✅ Real app launch updated in Firebase: ${data['appName']}');
    } catch (e) {
      print('❌ Error updating real app launch: $e');
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
