import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/alert_type.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.parentId,
    required super.childId,
    required super.alertType,
    required super.title,
    required super.body,
    super.data,
    required super.timestamp,
    super.isRead,
    super.readAt,
    super.actionUrl,
  });

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      parentId: entity.parentId,
      childId: entity.childId,
      alertType: entity.alertType,
      title: entity.title,
      body: entity.body,
      data: entity.data,
      timestamp: entity.timestamp,
      isRead: entity.isRead,
      readAt: entity.readAt,
      actionUrl: entity.actionUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'childId': childId,
      'alertType': alertType.value,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'actionUrl': actionUrl,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      parentId: map['parentId'] ?? '',
      childId: map['childId'] ?? '',
      alertType: AlertTypeExtension.fromString(map['alertType'] ?? 'general'),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      data: map['data'] as Map<String, dynamic>?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      actionUrl: map['actionUrl'] as String?,
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }
}

