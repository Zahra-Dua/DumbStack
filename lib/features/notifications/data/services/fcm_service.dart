import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FCM Service for managing Firebase Cloud Messaging
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _fcmToken;
  bool _initialized = false;

  /// Initialize FCM service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for notifications
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      print('🔔 FCM Permission Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM Permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ FCM Permission granted provisionally');
      } else {
        print('❌ FCM Permission denied');
        return;
      }

      // Get FCM token
      await _getFCMToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _saveTokenToFirestore(newToken);
      });

      _initialized = true;
      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    if (_fcmToken != null) return _fcmToken;
    await _getFCMToken();
    return _fcmToken;
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: $_fcmToken');
        await _saveTokenToFirestore(_fcmToken!);
      } else {
        print('⚠️ FCM Token is null');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('parent_uid') ?? prefs.getString('child_uid');
      final userType = prefs.getString('user_type') ?? 'unknown';

      if (userId == null) {
        print('⚠️ User ID not found, cannot save FCM token');
        return;
      }

      if (userType == 'parent') {
        // Save parent token
        await _firestore.collection('parents').doc(userId).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('✅ Parent FCM token saved to Firestore');
      } else if (userType == 'child') {
        // Save child token
        final parentId = prefs.getString('parent_uid');
        if (parentId != null) {
          await _firestore
              .collection('parents')
              .doc(parentId)
              .collection('children')
              .doc(userId)
              .set({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✅ Child FCM token saved to Firestore');
        }
      }
    } catch (e) {
      print('❌ Error saving FCM token to Firestore: $e');
    }
  }

  /// Get parent FCM token from Firestore
  Future<String?> getParentFCMToken(String parentId) async {
    try {
      final doc = await _firestore.collection('parents').doc(parentId).get();
      if (doc.exists) {
        return doc.data()?['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting parent FCM token: $e');
      return null;
    }
  }

  /// Get child FCM token from Firestore
  Future<String?> getChildFCMToken(String parentId, String childId) async {
    try {
      final doc = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      if (doc.exists) {
        return doc.data()?['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting child FCM token: $e');
      return null;
    }
  }

  /// Send FCM notification using HTTP API
  /// Note: In production, use Firebase Cloud Functions or Admin SDK
  Future<bool> sendNotification({
    required String toToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // For production, use Firebase Cloud Functions
      // This is a placeholder - you should implement this via Cloud Functions
      // or use Firebase Admin SDK from your backend
      
      print('📤 Sending FCM notification to token: $toToken');
      print('   Title: $title');
      print('   Body: $body');
      print('   Data: $data');

      // TODO: Implement actual FCM sending via Cloud Functions
      // For now, we'll save the notification to Firestore
      // and let Cloud Functions handle the actual sending
      
      return true;
    } catch (e) {
      print('❌ Error sending FCM notification: $e');
      return false;
    }
  }

  /// Subscribe to topic (for group notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }
}

