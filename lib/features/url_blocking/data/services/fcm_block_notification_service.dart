import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service to send FCM notifications when URLs are blocked
/// This ensures child device receives block updates even when app is backgrounded
class FcmBlockNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Send FCM notification to child device when URL is blocked
  /// Note: This should ideally be done via Cloud Function for security
  /// This is a client-side fallback - Cloud Function is recommended
  Future<void> notifyChildDeviceBlockUpdate({
    required String childId,
    required String parentId,
    required String url,
  }) async {
    try {
      // Get child's FCM token from Firestore
      final childDoc = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();

      if (!childDoc.exists) {
        print('⚠️ Child document not found: $childId');
        return;
      }

      final childData = childDoc.data();
      final fcmToken = childData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ Child FCM token not found: $childId');
        return;
      }

      // Send FCM data message (this requires server-side implementation)
      // For now, we'll create a notification document that Cloud Function can listen to
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('fcmNotifications')
          .add({
        'type': 'blockRulesUpdated',
        'url': url,
        'timestamp': FieldValue.serverTimestamp(),
        'fcmToken': fcmToken,
        'status': 'pending', // Cloud Function will process this
      });

      print('✅ FCM notification queued for child $childId');
    } catch (e) {
      print('❌ Error sending FCM notification: $e');
      // Don't throw - FCM is best effort, Firestore stream will still work
    }
  }

  /// Register child's FCM token
  Future<void> registerChildFcmToken({
    required String childId,
    required String parentId,
  }) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        print('⚠️ FCM token not available');
        return;
      }

      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ FCM token registered for child $childId');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _firestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token refreshed for child $childId');
      });
    } catch (e) {
      print('❌ Error registering FCM token: $e');
    }
  }
}

