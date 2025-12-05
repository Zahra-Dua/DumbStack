import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/alert_type.dart';
import '../models/notification_model.dart';
import 'fcm_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Service for sending different types of alerts
class AlertSenderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FCMService _fcmService = FCMService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Send suspicious message alert
  Future<void> sendSuspiciousMessageAlert({
    required String parentId,
    required String childId,
    required String messageContent,
    required String senderNumber,
    required String toxLabel,
    required double toxScore,
  }) async {
    try {
      final title = '🚨 Suspicious Message Detected';
      final body = 'Message from $senderNumber: ${messageContent.substring(0, messageContent.length > 50 ? 50 : messageContent.length)}...';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.suspiciousMessage,
        title: title,
        body: body,
        data: {
          'messageContent': messageContent,
          'senderNumber': senderNumber,
          'toxLabel': toxLabel,
          'toxScore': toxScore,
          'alertType': AlertType.suspiciousMessage.value,
        },
        timestamp: DateTime.now(),
        actionUrl: '/messages/suspicious',
      );

      await _sendAlert(notification);
      print('✅ Suspicious message alert sent');
    } catch (e) {
      print('❌ Error sending suspicious message alert: $e');
    }
  }

  /// Send suspicious call alert
  Future<void> sendSuspiciousCallAlert({
    required String parentId,
    required String childId,
    required String callerNumber,
    required String callerName,
    required String callType, // 'incoming', 'outgoing', 'missed'
    required int duration,
    String? transcription,
  }) async {
    try {
      final title = '📞 Suspicious Call Detected';
      final body = '$callType call from $callerName ($callerNumber) - Duration: ${duration}s';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.suspiciousCall,
        title: title,
        body: body,
        data: {
          'callerNumber': callerNumber,
          'callerName': callerName,
          'callType': callType,
          'duration': duration,
          'transcription': transcription,
          'alertType': AlertType.suspiciousCall.value,
        },
        timestamp: DateTime.now(),
        actionUrl: '/flagged-calls', // Navigate to flagged calls page
      );

      await _sendAlert(notification);
      print('✅ Suspicious call alert sent');
    } catch (e) {
      print('❌ Error sending suspicious call alert: $e');
    }
  }

  /// Send geofencing alert
  Future<void> sendGeofencingAlert({
    required String parentId,
    required String childId,
    required String zoneName,
    required String eventType, // 'entry' or 'exit'
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final title = eventType == 'entry'
          ? '✅ Child Entered Safe Zone'
          : '⚠️ Child Left Safe Zone';
      final body = '${eventType == 'entry' ? 'Entered' : 'Exited'} zone: $zoneName';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.geofencing,
        title: title,
        body: body,
        data: {
          'zoneName': zoneName,
          'eventType': eventType,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'alertType': AlertType.geofencing.value,
        },
        timestamp: DateTime.now(),
        actionUrl: '/location/tracking',
      );

      await _sendAlert(notification);
      print('✅ Geofencing alert sent');
    } catch (e) {
      print('❌ Error sending geofencing alert: $e');
    }
  }

  /// Send SOS alert
  Future<void> sendSOSAlert({
    required String parentId,
    required String childId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final title = '🚨 SOS EMERGENCY ALERT';
      
      // Create body with location information
      String body;
      if (latitude != 0.0 && longitude != 0.0) {
        if (address != null && address.isNotEmpty) {
          body = 'Your child has triggered an SOS alert!\n📍 Location: $address\nTap to view on map.';
        } else {
          body = 'Your child has triggered an SOS alert!\n📍 Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}\nTap to view on map.';
        }
      } else {
        body = 'Your child has triggered an SOS alert! Location unavailable.';
      }

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.sos,
        title: title,
        body: body,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address ?? '',
          'alertType': AlertType.sos.value,
          'priority': 'high',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        timestamp: DateTime.now(),
        actionUrl: '/sos/emergency',
      );

      await _sendAlert(notification, priority: 'high');
      print('✅ SOS alert sent with location: $latitude, $longitude');
      if (address != null) {
        print('✅ SOS address: $address');
      }
    } catch (e) {
      print('❌ Error sending SOS alert: $e');
    }
  }

  /// Send screen time limit alert
  Future<void> sendScreenTimeLimitAlert({
    required String parentId,
    required String childId,
    required int dailyLimitMinutes,
    required int currentUsageMinutes,
  }) async {
    try {
      final title = '⏰ Screen Time Limit Reached';
      final body = 'Daily limit of $dailyLimitMinutes minutes reached. Current usage: $currentUsageMinutes minutes';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.screenTimeLimit,
        title: title,
        body: body,
        data: {
          'dailyLimitMinutes': dailyLimitMinutes,
          'currentUsageMinutes': currentUsageMinutes,
          'alertType': AlertType.screenTimeLimit.value,
        },
        timestamp: DateTime.now(),
        actionUrl: '/screen-time/limits',
      );

      await _sendAlert(notification);
      print('✅ Screen time limit alert sent');
    } catch (e) {
      print('❌ Error sending screen time limit alert: $e');
    }
  }

  /// Send app/website blocked alert
  Future<void> sendAppWebsiteBlockedAlert({
    required String parentId,
    required String childId,
    required String blockedItem, // App name or website URL
    required String blockType, // 'app' or 'website'
  }) async {
    try {
      final title = '🚫 Blocked ${blockType == 'app' ? 'App' : 'Website'} Access';
      final body = 'Child attempted to access: $blockedItem';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.appWebsiteBlocked,
        title: title,
        body: body,
        data: {
          'blockedItem': blockedItem,
          'blockType': blockType,
          'alertType': AlertType.appWebsiteBlocked.value,
        },
        timestamp: DateTime.now(),
        actionUrl: '/content-control/blocks',
      );

      await _sendAlert(notification);
      print('✅ App/Website blocked alert sent');
    } catch (e) {
      print('❌ Error sending app/website blocked alert: $e');
    }
  }

  /// Send emotional distress alert
  Future<void> sendEmotionalDistressAlert({
    required String parentId,
    required String childId,
    required String distressType,
    required double confidenceScore,
    String? details,
  }) async {
    try {
      final title = '😔 Emotional Distress Detected';
      final body = 'AI detected signs of $distressType (Confidence: ${(confidenceScore * 100).toStringAsFixed(0)}%)';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.emotionalDistress,
        title: title,
        body: body,
        data: {
          'distressType': distressType,
          'confidenceScore': confidenceScore,
          'details': details,
          'alertType': AlertType.emotionalDistress.value,
        },
        timestamp: DateTime.now(),
        actionUrl: '/wellbeing/emotional',
      );

      await _sendAlert(notification);
      print('✅ Emotional distress alert sent');
    } catch (e) {
      print('❌ Error sending emotional distress alert: $e');
    }
  }

  /// Send toxic behavior pattern alert
  Future<void> sendToxicBehaviorPatternAlert({
    required String parentId,
    required String childId,
    required String patternType,
    required int occurrenceCount,
    String? details,
  }) async {
    try {
      final title = '⚠️ Toxic Behavior Pattern Detected';
      final body = 'Pattern: $patternType (Occurred $occurrenceCount times)';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.toxicBehaviorPattern,
        title: title,
        body: body,
        data: {
          'patternType': patternType,
          'occurrenceCount': occurrenceCount,
          'details': details,
          'alertType': AlertType.toxicBehaviorPattern.value,
        },
        timestamp: DateTime.now(),
        actionUrl: '/wellbeing/behavior',
      );

      await _sendAlert(notification);
      print('✅ Toxic behavior pattern alert sent');
    } catch (e) {
      print('❌ Error sending toxic behavior pattern alert: $e');
    }
  }

  /// Send suspicious contacts pattern alert
  Future<void> sendSuspiciousContactsPatternAlert({
    required String parentId,
    required String childId,
    required List<String> suspiciousContacts,
    required String patternDescription,
  }) async {
    try {
      final title = '👥 Suspicious Contacts Pattern';
      final body = 'Pattern detected: $patternDescription (${suspiciousContacts.length} contacts)';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.suspiciousContactsPattern,
        title: title,
        body: body,
        data: {
          'suspiciousContacts': suspiciousContacts,
          'patternDescription': patternDescription,
          'alertType': AlertType.suspiciousContactsPattern.value,
        },
        timestamp: DateTime.now(),
        actionUrl: '/contacts/suspicious',
      );

      await _sendAlert(notification);
      print('✅ Suspicious contacts pattern alert sent');
    } catch (e) {
      print('❌ Error sending suspicious contacts pattern alert: $e');
    }
  }

  /// Send predictive threat alert
  Future<void> sendPredictiveThreatAlert({
    required String parentId,
    required String childId,
    required String threatType,
    required double riskScore,
    required String prediction,
    String? recommendedAction,
  }) async {
    try {
      final title = '🔮 Predictive Threat Alert';
      final body = 'Risk: $threatType (Score: ${(riskScore * 100).toStringAsFixed(0)}%) - $prediction';

      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.predictiveThreat,
        title: title,
        body: body,
        data: {
          'threatType': threatType,
          'riskScore': riskScore,
          'prediction': prediction,
          'recommendedAction': recommendedAction,
          'alertType': AlertType.predictiveThreat.value,
        },
        timestamp: DateTime.now(),
        actionUrl: '/threats/predictive',
      );

      await _sendAlert(notification);
      print('✅ Predictive threat alert sent');
    } catch (e) {
      print('❌ Error sending predictive threat alert: $e');
    }
  }

  /// Send simple test notification (for testing purposes)
  Future<void> sendTestNotification({
    required String parentId,
    required String childId,
    required String title,
    required String body,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        childId: childId,
        alertType: AlertType.general,
        title: title,
        body: body,
        data: {
          'alertType': 'test',
          'childId': childId,
        },
        timestamp: DateTime.now(),
        actionUrl: '/children/list',
      );

      await _sendAlert(notification);
      print('✅ Test notification sent: $title');
    } catch (e) {
      print('❌ Error sending test notification: $e');
      rethrow;
    }
  }

  /// Internal method to send alert via FCM
  Future<void> _sendAlert(
    NotificationModel notification, {
    String priority = 'normal',
  }) async {
    try {
      // Save notification to Firestore under child's notifications collection
      // Path: parents/{parentId}/children/{childId}/notifications
      print('📝 [AlertSender] Saving notification to Firestore...');
      print('📝 [AlertSender] Path: parents/${notification.parentId}/children/${notification.childId}/notifications');
      print('📝 [AlertSender] Notification data: ${notification.toMap()}');
      
      final docRef = await _firestore
          .collection('parents')
          .doc(notification.parentId)
          .collection('children')
          .doc(notification.childId)
          .collection('notifications')
          .add(notification.toMap());
      
      print('✅ [AlertSender] Notification saved to Firestore with ID: ${docRef.id}');
      print('✅ [AlertSender] Full path: parents/${notification.parentId}/children/${notification.childId}/notifications/${docRef.id}');

      // Get parent FCM token
      final parentToken = await _fcmService.getParentFCMToken(notification.parentId);

      if (parentToken != null) {
        // Send via Cloud Functions (recommended approach)
        try {
          final callable = _functions.httpsCallable('sendNotification');
          await callable.call({
            'token': parentToken,
            'title': notification.title,
            'body': notification.body,
            'data': notification.data,
            'priority': priority,
          });
          print('✅ Notification sent via Cloud Function');
        } catch (e) {
          print('⚠️ Cloud Function not available, using direct FCM: $e');
          // Fallback: Use direct FCM (requires server key - not recommended for production)
          await _fcmService.sendNotification(
            toToken: parentToken,
            title: notification.title,
            body: notification.body,
            data: notification.data,
          );
        }
      } else {
        print('⚠️ [AlertSender] Parent FCM token not found for parentId: ${notification.parentId}');
      }
    } catch (e, stackTrace) {
      print('❌ [AlertSender] Error in _sendAlert: $e');
      print('❌ [AlertSender] Stack trace: $stackTrace');
      // Re-throw to ensure caller knows about the error
      rethrow;
    }
  }
}

