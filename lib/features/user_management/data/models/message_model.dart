import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String childId;
  final String parentId;
  final String senderId; // Who sent the message (parent or child)
  final String senderType; // 'parent' or 'child'
  final String content;
  final String messageType; // 'text', 'image', 'video', 'audio', 'location', 'call_log', 'sms'
  final Map<String, dynamic>? metadata; // Additional data like file URLs, location coords, etc.
  final bool isRead;
  final bool isBlocked;
  final DateTime timestamp;
  final DateTime? readAt;
  final String? replyToMessageId; // For message replies
  final List<String>? attachments; // File URLs for attachments
  
  // SMS Analysis fields
  final int? flag; // SMS flag (0 = normal, 1 = spam, etc.)
  final double? toxScore; // Toxicity score (0.0 to 1.0)
  final String? toxLabel; // Toxicity label (safe, toxic, etc.)

  MessageModel({
    required this.messageId,
    required this.childId,
    required this.parentId,
    required this.senderId,
    required this.senderType,
    required this.content,
    this.messageType = 'text',
    this.metadata,
    this.isRead = false,
    this.isBlocked = false,
    required this.timestamp,
    this.readAt,
    this.replyToMessageId,
    this.attachments,
    this.flag,
    this.toxScore,
    this.toxLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'childId': childId,
      'parentId': parentId,
      'senderId': senderId,
      'senderType': senderType,
      'content': content,
      'messageType': messageType,
      'metadata': metadata,
      'isRead': isRead,
      'isBlocked': isBlocked,
      'timestamp': timestamp,
      'readAt': readAt,
      'replyToMessageId': replyToMessageId,
      'attachments': attachments,
      'flag': flag,
      'toxScore': toxScore,
      'toxLabel': toxLabel,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      childId: map['childId'] ?? '',
      parentId: map['parentId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderType: map['senderType'] ?? 'child',
      content: map['content'] ?? '',
      messageType: map['messageType'] ?? 'text',
      metadata: map['metadata'],
      isRead: map['isRead'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      replyToMessageId: map['replyToMessageId'],
      attachments: map['attachments'] != null 
          ? List<String>.from(map['attachments']) 
          : null,
      flag: map['flag'],
      toxScore: map['toxScore']?.toDouble(),
      toxLabel: map['toxLabel'],
    );
  }

  /// Create a text message
  factory MessageModel.createTextMessage({
    required String messageId,
    required String childId,
    required String parentId,
    required String senderId,
    required String senderType,
    required String content,
    String? replyToMessageId,
  }) {
    return MessageModel(
      messageId: messageId,
      childId: childId,
      parentId: parentId,
      senderId: senderId,
      senderType: senderType,
      content: content,
      messageType: 'text',
      replyToMessageId: replyToMessageId,
      timestamp: DateTime.now(),
    );
  }

  /// Create an image message
  factory MessageModel.createImageMessage({
    required String messageId,
    required String childId,
    required String parentId,
    required String senderId,
    required String senderType,
    required String imageUrl,
    String? caption,
    String? replyToMessageId,
  }) {
    return MessageModel(
      messageId: messageId,
      childId: childId,
      parentId: parentId,
      senderId: senderId,
      senderType: senderType,
      content: caption ?? '',
      messageType: 'image',
      attachments: [imageUrl],
      replyToMessageId: replyToMessageId,
      timestamp: DateTime.now(),
    );
  }

  /// Create a call log message
  factory MessageModel.createCallLogMessage({
    required String messageId,
    required String childId,
    required String parentId,
    required String phoneNumber,
    required String callType, // 'incoming', 'outgoing', 'missed'
    required int duration, // in seconds
    required DateTime callTime,
  }) {
    return MessageModel(
      messageId: messageId,
      childId: childId,
      parentId: parentId,
      senderId: childId, // Child made/received the call
      senderType: 'child',
      content: '$callType call to $phoneNumber',
      messageType: 'call_log',
      metadata: {
        'phoneNumber': phoneNumber,
        'callType': callType,
        'duration': duration,
        'callTime': callTime.toIso8601String(),
      },
      timestamp: DateTime.now(),
    );
  }

  /// Create an SMS message
  factory MessageModel.createSMSMessage({
    required String messageId,
    required String childId,
    required String parentId,
    required String phoneNumber,
    required String messageBody,
    required String smsType, // 'sent', 'received'
    required DateTime smsTime,
    int? flag,
    double? toxScore,
    String? toxLabel,
  }) {
    return MessageModel(
      messageId: messageId,
      childId: childId,
      parentId: parentId,
      senderId: childId, // Child sent/received the SMS
      senderType: 'child',
      content: messageBody,
      messageType: 'sms',
      metadata: {
        'phoneNumber': phoneNumber,
        'smsType': smsType,
        'smsTime': smsTime.toIso8601String(),
      },
      timestamp: DateTime.now(),
      flag: flag,
      toxScore: toxScore,
      toxLabel: toxLabel,
    );
  }

  /// Create SMS message from AnalyzedSmsModel
  factory MessageModel.fromAnalyzedSms({
    required String childId,
    required String parentId,
    required String analyzedSmsId,
    required String sender,
    required String body,
    required String timestampIso,
    required int flag,
    required double toxScore,
    required String toxLabel,
    String smsType = 'received', // Default to received
  }) {
    return MessageModel(
      messageId: analyzedSmsId,
      childId: childId,
      parentId: parentId,
      senderId: childId, // Child received the SMS
      senderType: 'child',
      content: body,
      messageType: 'sms',
      metadata: {
        'phoneNumber': sender,
        'smsType': smsType,
        'smsTime': timestampIso,
      },
      timestamp: DateTime.parse(timestampIso),
      flag: flag,
      toxScore: toxScore,
      toxLabel: toxLabel,
    );
  }

  /// Create a location message
  factory MessageModel.createLocationMessage({
    required String messageId,
    required String childId,
    required String parentId,
    required double latitude,
    required double longitude,
    String? address,
    double? accuracy,
  }) {
    return MessageModel(
      messageId: messageId,
      childId: childId,
      parentId: parentId,
      senderId: childId,
      senderType: 'child',
      content: address ?? 'Location shared',
      messageType: 'location',
      metadata: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'accuracy': accuracy,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Mark message as read
  MessageModel markAsRead() {
    return MessageModel(
      messageId: messageId,
      childId: childId,
      parentId: parentId,
      senderId: senderId,
      senderType: senderType,
      content: content,
      messageType: messageType,
      metadata: metadata,
      isRead: true,
      isBlocked: isBlocked,
      timestamp: timestamp,
      readAt: DateTime.now(),
      replyToMessageId: replyToMessageId,
      attachments: attachments,
    );
  }

  /// Block/unblock message
  MessageModel toggleBlock() {
    return MessageModel(
      messageId: messageId,
      childId: childId,
      parentId: parentId,
      senderId: senderId,
      senderType: senderType,
      content: content,
      messageType: messageType,
      metadata: metadata,
      isRead: isRead,
      isBlocked: !isBlocked,
      timestamp: timestamp,
      readAt: readAt,
      replyToMessageId: replyToMessageId,
      attachments: attachments,
    );
  }

  /// Get display text for message
  String get displayText {
    switch (messageType) {
      case 'text':
        return content;
      case 'image':
        return '📷 Image${content.isNotEmpty ? ': $content' : ''}';
      case 'video':
        return '🎥 Video${content.isNotEmpty ? ': $content' : ''}';
      case 'audio':
        return '🎵 Audio${content.isNotEmpty ? ': $content' : ''}';
      case 'call_log':
        return '📞 $content';
      case 'sms':
        return '💬 SMS: $content';
      case 'location':
        return '📍 Location: $content';
      default:
        return content;
    }
  }

  /// Check if message is from parent
  bool get isFromParent => senderType == 'parent';

  /// Check if message is from child
  bool get isFromChild => senderType == 'child';

  /// Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Update message with analysis data
  MessageModel updateWithAnalysis({
    int? flag,
    double? toxScore,
    String? toxLabel,
  }) {
    return MessageModel(
      messageId: messageId,
      childId: childId,
      parentId: parentId,
      senderId: senderId,
      senderType: senderType,
      content: content,
      messageType: messageType,
      metadata: metadata,
      isRead: isRead,
      isBlocked: isBlocked,
      timestamp: timestamp,
      readAt: readAt,
      replyToMessageId: replyToMessageId,
      attachments: attachments,
      flag: flag ?? this.flag,
      toxScore: toxScore ?? this.toxScore,
      toxLabel: toxLabel ?? this.toxLabel,
    );
  }

  /// Get toxicity level based on score
  String get toxicityLevel {
    if (toxScore == null) return 'Unknown';
    if (toxScore! < 0.3) return 'Safe';
    if (toxScore! < 0.6) return 'Moderate';
    if (toxScore! < 0.8) return 'High';
    return 'Very High';
  }

  /// Get flag description
  String get flagDescription {
    switch (flag) {
      case 0:
        return 'Normal';
      case 1:
        return 'Spam';
      case 2:
        return 'Suspicious';
      case 3:
        return 'Blocked';
      default:
        return 'Unknown';
    }
  }

  /// Check if message is flagged as problematic
  bool get isFlagged {
    return flag != null && flag! > 0;
  }

  /// Check if message is toxic
  bool get isToxic {
    return toxScore != null && toxScore! > 0.5;
  }
}
