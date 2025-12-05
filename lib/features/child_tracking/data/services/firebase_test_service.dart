import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app_limits/data/models/app_usage_firebase.dart';
import '../../../url_tracking/data/services/url_tracking_firebase_service.dart';

class FirebaseTestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UrlTrackingFirebaseService _urlService = UrlTrackingFirebaseService();

  // Create sample URL data and upload to Firebase
  Future<void> createSampleUrlData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }

      final childId = currentUser.uid;
      final parentId = currentUser.uid; // Using same ID for testing

      print('🚀 Creating sample URL data for child: $childId');

      final sampleUrls = [
        {
          'url': 'https://www.youtube.com',
          'title': 'YouTube - Watch Videos',
          'packageName': 'com.google.android.youtube',
          'browserName': 'Chrome',
          'visitedAt': DateTime.now().subtract(Duration(hours: 3)),
          'metadata': {'category': 'entertainment', 'risk_level': 'low'},
          'isBlocked': false,
        },
        {
          'url': 'https://www.facebook.com',
          'title': 'Facebook',
          'packageName': 'com.facebook.katana',
          'browserName': 'Chrome',
          'visitedAt': DateTime.now().subtract(Duration(hours: 2)),
          'metadata': {'category': 'social', 'risk_level': 'medium'},
          'isBlocked': false,
        },
        {
          'url': 'https://www.instagram.com',
          'title': 'Instagram',
          'packageName': 'com.instagram.android',
          'browserName': 'Chrome',
          'visitedAt': DateTime.now().subtract(Duration(hours: 1)),
          'metadata': {'category': 'social', 'risk_level': 'medium'},
          'isBlocked': false,
        },
        {
          'url': 'https://www.google.com',
          'title': 'Google Search',
          'packageName': 'com.android.chrome',
          'browserName': 'Chrome',
          'visitedAt': DateTime.now().subtract(Duration(minutes: 30)),
          'metadata': {'category': 'search', 'risk_level': 'low'},
          'isBlocked': false,
        },
        {
          'url': 'https://www.example-bad-site.com',
          'title': 'Suspicious Site',
          'packageName': 'com.android.chrome',
          'browserName': 'Chrome',
          'visitedAt': DateTime.now().subtract(Duration(minutes: 10)),
          'metadata': {'category': 'unknown', 'risk_level': 'high'},
          'isBlocked': true,
        },
      ];

      for (int i = 0; i < sampleUrls.length; i++) {
        final urlData = sampleUrls[i];
        
        await _urlService.uploadUrlToFirebase(
          url: urlData['url'] as String,
          title: urlData['title'] as String,
          packageName: urlData['packageName'] as String,
          childId: childId,
          parentId: parentId,
          browserName: urlData['browserName'] as String,
          metadata: urlData['metadata'] as Map<String, dynamic>?,
        );

        print('✅ URL uploaded: ${urlData['url']}');
      }

      print('✅ All URL data uploaded successfully!');
    } catch (e) {
      print('❌ Error creating URL data: $e');
    }
  }

  // Create sample app usage data and upload to Firebase
  Future<void> createSampleAppData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }

      final childId = currentUser.uid;
      final parentId = currentUser.uid; // Using same ID for testing

      print('🚀 Creating sample app usage data for child: $childId');

      final sampleApps = [
        {
          'packageName': 'com.google.android.youtube',
          'appName': 'YouTube',
          'usageDuration': 180, // 3 hours
          'launchCount': 25,
          'lastUsed': DateTime.now().subtract(Duration(minutes: 5)),
          'appIcon': null,
          'metadata': {'category': 'entertainment', 'risk_level': 'low'},
          'isSystemApp': false,
          'riskScore': 0.2,
        },
        {
          'packageName': 'com.facebook.katana',
          'appName': 'Facebook',
          'usageDuration': 120, // 2 hours
          'launchCount': 15,
          'lastUsed': DateTime.now().subtract(Duration(minutes: 10)),
          'appIcon': null,
          'metadata': {'category': 'social', 'risk_level': 'medium'},
          'isSystemApp': false,
          'riskScore': 0.6,
        },
        {
          'packageName': 'com.instagram.android',
          'appName': 'Instagram',
          'usageDuration': 90, // 1.5 hours
          'launchCount': 20,
          'lastUsed': DateTime.now().subtract(Duration(minutes: 2)),
          'appIcon': null,
          'metadata': {'category': 'social', 'risk_level': 'medium'},
          'isSystemApp': false,
          'riskScore': 0.5,
        },
        {
          'packageName': 'com.android.chrome',
          'appName': 'Chrome Browser',
          'usageDuration': 60, // 1 hour
          'launchCount': 30,
          'lastUsed': DateTime.now().subtract(Duration(minutes: 1)),
          'appIcon': null,
          'metadata': {'category': 'browser', 'risk_level': 'low'},
          'isSystemApp': false,
          'riskScore': 0.1,
        },
        {
          'packageName': 'com.whatsapp',
          'appName': 'WhatsApp',
          'usageDuration': 45, // 45 minutes
          'launchCount': 35,
          'lastUsed': DateTime.now().subtract(Duration(seconds: 30)),
          'appIcon': null,
          'metadata': {'category': 'messaging', 'risk_level': 'low'},
          'isSystemApp': false,
          'riskScore': 0.3,
        },
        {
          'packageName': 'com.android.settings',
          'appName': 'Settings',
          'usageDuration': 15, // 15 minutes
          'launchCount': 5,
          'lastUsed': DateTime.now().subtract(Duration(minutes: 15)),
          'appIcon': null,
          'metadata': {'category': 'system', 'risk_level': 'low'},
          'isSystemApp': true,
          'riskScore': 0.0,
        },
      ];

      for (int i = 0; i < sampleApps.length; i++) {
        final appData = sampleApps[i];
        final appId = 'app_${appData['packageName']}_${DateTime.now().millisecondsSinceEpoch}';
        
        final appUsage = AppUsageFirebase(
          id: appId,
          packageName: appData['packageName'] as String,
          appName: appData['appName'] as String,
          usageDuration: appData['usageDuration'] as int,
          launchCount: appData['launchCount'] as int,
          lastUsed: appData['lastUsed'] as DateTime,
          appIcon: appData['appIcon'] as String?,
          metadata: appData['metadata'] as Map<String, dynamic>?,
          isSystemApp: appData['isSystemApp'] as bool,
          riskScore: appData['riskScore'] as double?,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('appUsage')
            .doc(appId)
            .set(appUsage.toJson());

        print('✅ App usage uploaded: ${appData['appName']}');
      }

      print('✅ All app usage data uploaded successfully!');
    } catch (e) {
      print('❌ Error creating app usage data: $e');
    }
  }

  // Create all sample data
  Future<void> createAllSampleData() async {
    try {
      print('🚀 Creating all sample data...');
      
      await createSampleUrlData();
      await createSampleAppData();
      
      print('✅ All sample data created successfully!');
    } catch (e) {
      print('❌ Error creating sample data: $e');
    }
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
