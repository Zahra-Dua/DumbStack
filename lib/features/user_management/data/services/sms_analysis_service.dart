import '../models/message_model.dart';
import '../../../user_management/data/datasources/firebase_parent_service.dart';

class SmsAnalysisService {
  final FirebaseParentService _firebaseService = FirebaseParentService();

  /// Convert AnalyzedSmsModel to MessageModel and save to Firebase
  Future<String> saveAnalyzedSms({
    required String childId,
    required String parentId,
    required String analyzedSmsId,
    required String sender,
    required String body,
    required String timestampIso,
    required int flag,
    required double toxScore,
    required String toxLabel,
    String smsType = 'received',
  }) async {
    try {
      // Create MessageModel from AnalyzedSmsModel data
      final message = MessageModel.fromAnalyzedSms(
        childId: childId,
        parentId: parentId,
        analyzedSmsId: analyzedSmsId,
        sender: sender,
        body: body,
        timestampIso: timestampIso,
        flag: flag,
        toxScore: toxScore,
        toxLabel: toxLabel,
        smsType: smsType,
      );

      // Save to Firebase
      final messageId = await _firebaseService.addMessage(parentId, childId, message);
      
      return messageId;
    } catch (e) {
      throw Exception('Failed to save analyzed SMS: $e');
    }
  }

  /// Update existing message with analysis data
  Future<void> updateMessageAnalysis({
    required String parentId,
    required String childId,
    required String messageId,
    required int flag,
    required double toxScore,
    required String toxLabel,
  }) async {
    try {
      // Get existing message
      final messages = await _firebaseService.getMessages(parentId, childId);
      final message = messages.firstWhere((m) => m.messageId == messageId);
      
      // Update with analysis data
      final updatedMessage = message.updateWithAnalysis(
        flag: flag,
        toxScore: toxScore,
        toxLabel: toxLabel,
      );

      // Update in Firebase
      await _firebaseService.updateMessage(parentId, childId, updatedMessage);
    } catch (e) {
      throw Exception('Failed to update message analysis: $e');
    }
  }

  /// Get messages by toxicity level
  Future<List<MessageModel>> getMessagesByToxicity({
    required String parentId,
    required String childId,
    required String toxicityLevel, // 'safe', 'moderate', 'high', 'very_high'
  }) async {
    try {
      final messages = await _firebaseService.getMessages(parentId, childId);
      
      return messages.where((message) {
        if (message.toxScore == null) return false;
        
        switch (toxicityLevel.toLowerCase()) {
          case 'safe':
            return message.toxScore! < 0.3;
          case 'moderate':
            return message.toxScore! >= 0.3 && message.toxScore! < 0.6;
          case 'high':
            return message.toxScore! >= 0.6 && message.toxScore! < 0.8;
          case 'very_high':
            return message.toxScore! >= 0.8;
          default:
            return false;
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to get messages by toxicity: $e');
    }
  }

  /// Get flagged messages
  Future<List<MessageModel>> getFlaggedMessages({
    required String parentId,
    required String childId,
  }) async {
    try {
      final messages = await _firebaseService.getMessages(parentId, childId);
      return messages.where((message) => message.isFlagged).toList();
    } catch (e) {
      throw Exception('Failed to get flagged messages: $e');
    }
  }

  /// Get toxic messages
  Future<List<MessageModel>> getToxicMessages({
    required String parentId,
    required String childId,
  }) async {
    try {
      final messages = await _firebaseService.getMessages(parentId, childId);
      return messages.where((message) => message.isToxic).toList();
    } catch (e) {
      throw Exception('Failed to get toxic messages: $e');
    }
  }

  /// Get SMS analysis statistics
  Future<Map<String, dynamic>> getAnalysisStats({
    required String parentId,
    required String childId,
  }) async {
    try {
      final messages = await _firebaseService.getMessages(parentId, childId);
      final smsMessages = messages.where((m) => m.messageType == 'sms').toList();
      
      if (smsMessages.isEmpty) {
        return {
          'total': 0,
          'analyzed': 0,
          'flagged': 0,
          'toxic': 0,
          'safe': 0,
          'moderate': 0,
          'high': 0,
          'very_high': 0,
          'averageToxScore': 0.0,
        };
      }

      final analyzed = smsMessages.where((m) => m.toxScore != null).toList();
      final flagged = smsMessages.where((m) => m.isFlagged).toList();
      final toxic = smsMessages.where((m) => m.isToxic).toList();
      
      final safe = analyzed.where((m) => m.toxScore! < 0.3).length;
      final moderate = analyzed.where((m) => m.toxScore! >= 0.3 && m.toxScore! < 0.6).length;
      final high = analyzed.where((m) => m.toxScore! >= 0.6 && m.toxScore! < 0.8).length;
      final veryHigh = analyzed.where((m) => m.toxScore! >= 0.8).length;
      
      final averageToxScore = analyzed.isNotEmpty
          ? analyzed.map((m) => m.toxScore!).reduce((a, b) => a + b) / analyzed.length
          : 0.0;

      return {
        'total': smsMessages.length,
        'analyzed': analyzed.length,
        'flagged': flagged.length,
        'toxic': toxic.length,
        'safe': safe,
        'moderate': moderate,
        'high': high,
        'very_high': veryHigh,
        'averageToxScore': averageToxScore,
      };
    } catch (e) {
      throw Exception('Failed to get analysis stats: $e');
    }
  }

  /// Batch save multiple analyzed SMS messages
  Future<List<String>> batchSaveAnalyzedSms({
    required String childId,
    required String parentId,
    required List<Map<String, dynamic>> analyzedSmsList,
  }) async {
    try {
      final List<String> messageIds = [];
      
      for (final smsData in analyzedSmsList) {
        final messageId = await saveAnalyzedSms(
          childId: childId,
          parentId: parentId,
          analyzedSmsId: smsData['id'] ?? '',
          sender: smsData['sender'] ?? '',
          body: smsData['body'] ?? '',
          timestampIso: smsData['timestampIso'] ?? '',
          flag: smsData['flag'] ?? 0,
          toxScore: smsData['toxScore']?.toDouble() ?? 0.0,
          toxLabel: smsData['toxLabel'] ?? 'unknown',
          smsType: smsData['smsType'] ?? 'received',
        );
        messageIds.add(messageId);
      }
      
      return messageIds;
    } catch (e) {
      throw Exception('Failed to batch save analyzed SMS: $e');
    }
  }

  /// Get recent toxic messages across all children
  Future<List<MessageModel>> getRecentToxicMessages({
    required String parentId,
    int limit = 20,
  }) async {
    try {
      final recentMessages = await _firebaseService.getRecentMessages(parentId, limit: limit);
      return recentMessages.where((m) => m.isToxic).toList();
    } catch (e) {
      throw Exception('Failed to get recent toxic messages: $e');
    }
  }

  /// Get recent flagged messages across all children
  Future<List<MessageModel>> getRecentFlaggedMessages({
    required String parentId,
    int limit = 20,
  }) async {
    try {
      final recentMessages = await _firebaseService.getRecentMessages(parentId, limit: limit);
      return recentMessages.where((m) => m.isFlagged).toList();
    } catch (e) {
      throw Exception('Failed to get recent flagged messages: $e');
    }
  }
}
