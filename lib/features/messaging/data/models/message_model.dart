import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final String messageType; // 'text', 'image', 'location', 'system'
  final bool isRead;
  final bool isSuspicious;
  final String? parentId;
  final String? childId;
  final double? riskScore;
  final String? toxicType; // 'spam', 'harassment', 'suspicious'
  final Map<String, dynamic>? analysisData;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.messageType = 'text',
    this.isRead = false,
    this.isSuspicious = false,
    this.parentId,
    this.childId,
    this.riskScore,
    this.toxicType,
    this.analysisData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp,
      'messageType': messageType,
      'isRead': isRead,
      'isSuspicious': isSuspicious,
      'parentId': parentId,
      'childId': childId,
      'riskScore': riskScore,
      'toxicType': toxicType,
      'analysisData': analysisData,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      messageType: map['messageType'] ?? 'text',
      isRead: map['isRead'] ?? false,
      isSuspicious: map['isSuspicious'] ?? false,
      parentId: map['parentId'],
      childId: map['childId'],
      riskScore: map['riskScore']?.toDouble(),
      toxicType: map['toxicType'],
      analysisData: map['analysisData'],
    );
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    String? messageType,
    bool? isRead,
    bool? isSuspicious,
    String? parentId,
    String? childId,
    double? riskScore,
    String? toxicType,
    Map<String, dynamic>? analysisData,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      isSuspicious: isSuspicious ?? this.isSuspicious,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      riskScore: riskScore ?? this.riskScore,
      toxicType: toxicType ?? this.toxicType,
      analysisData: analysisData ?? this.analysisData,
    );
  }
}