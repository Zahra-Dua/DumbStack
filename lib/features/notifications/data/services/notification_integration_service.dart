import 'package:get_it/get_it.dart';
import 'alert_sender_service.dart';

/// Service to integrate notifications with other modules
class NotificationIntegrationService {
  final AlertSenderService _alertSenderService;

  NotificationIntegrationService() : _alertSenderService = GetIt.instance<AlertSenderService>();

  /// Call this when a suspicious message is detected
  Future<void> onSuspiciousMessageDetected({
    required String parentId,
    required String childId,
    required String messageContent,
    required String senderNumber,
    required String toxLabel,
    required double toxScore,
  }) async {
    await _alertSenderService.sendSuspiciousMessageAlert(
      parentId: parentId,
      childId: childId,
      messageContent: messageContent,
      senderNumber: senderNumber,
      toxLabel: toxLabel,
      toxScore: toxScore,
    );
  }

  /// Call this when a suspicious call is detected
  Future<void> onSuspiciousCallDetected({
    required String parentId,
    required String childId,
    required String callerNumber,
    required String callerName,
    required String callType,
    required int duration,
    String? transcription,
  }) async {
    await _alertSenderService.sendSuspiciousCallAlert(
      parentId: parentId,
      childId: childId,
      callerNumber: callerNumber,
      callerName: callerName,
      callType: callType,
      duration: duration,
      transcription: transcription,
    );
  }

  /// Call this when geofencing event occurs
  Future<void> onGeofencingEvent({
    required String parentId,
    required String childId,
    required String zoneName,
    required String eventType,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    await _alertSenderService.sendGeofencingAlert(
      parentId: parentId,
      childId: childId,
      zoneName: zoneName,
      eventType: eventType,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  /// Call this when screen time limit is reached
  Future<void> onScreenTimeLimitReached({
    required String parentId,
    required String childId,
    required int dailyLimitMinutes,
    required int currentUsageMinutes,
  }) async {
    await _alertSenderService.sendScreenTimeLimitAlert(
      parentId: parentId,
      childId: childId,
      dailyLimitMinutes: dailyLimitMinutes,
      currentUsageMinutes: currentUsageMinutes,
    );
  }

  /// Call this when app/website is blocked
  Future<void> onAppWebsiteBlocked({
    required String parentId,
    required String childId,
    required String blockedItem,
    required String blockType,
  }) async {
    await _alertSenderService.sendAppWebsiteBlockedAlert(
      parentId: parentId,
      childId: childId,
      blockedItem: blockedItem,
      blockType: blockType,
    );
  }

  /// Call this when emotional distress is detected by AI
  Future<void> onEmotionalDistressDetected({
    required String parentId,
    required String childId,
    required String distressType,
    required double confidenceScore,
    String? details,
  }) async {
    await _alertSenderService.sendEmotionalDistressAlert(
      parentId: parentId,
      childId: childId,
      distressType: distressType,
      confidenceScore: confidenceScore,
      details: details,
    );
  }

  /// Call this when toxic behavior pattern is detected
  Future<void> onToxicBehaviorPatternDetected({
    required String parentId,
    required String childId,
    required String patternType,
    required int occurrenceCount,
    String? details,
  }) async {
    await _alertSenderService.sendToxicBehaviorPatternAlert(
      parentId: parentId,
      childId: childId,
      patternType: patternType,
      occurrenceCount: occurrenceCount,
      details: details,
    );
  }

  /// Call this when suspicious contacts pattern is detected
  Future<void> onSuspiciousContactsPatternDetected({
    required String parentId,
    required String childId,
    required List<String> suspiciousContacts,
    required String patternDescription,
  }) async {
    await _alertSenderService.sendSuspiciousContactsPatternAlert(
      parentId: parentId,
      childId: childId,
      suspiciousContacts: suspiciousContacts,
      patternDescription: patternDescription,
    );
  }

  /// Call this when predictive threat is detected
  Future<void> onPredictiveThreatDetected({
    required String parentId,
    required String childId,
    required String threatType,
    required double riskScore,
    required String prediction,
    String? recommendedAction,
  }) async {
    await _alertSenderService.sendPredictiveThreatAlert(
      parentId: parentId,
      childId: childId,
      threatType: threatType,
      riskScore: riskScore,
      prediction: prediction,
      recommendedAction: recommendedAction,
    );
  }
}

