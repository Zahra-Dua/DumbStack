import 'package:equatable/equatable.dart';
import 'alert_type.dart';

/// Notification entity representing an alert/notification
class NotificationEntity extends Equatable {
  final String id;
  final String parentId;
  final String childId;
  final AlertType alertType;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;
  final String? actionUrl; // Deep link or route to open when notification is tapped

  const NotificationEntity({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.alertType,
    required this.title,
    required this.body,
    this.data,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    this.actionUrl,
  });

  @override
  List<Object?> get props => [
        id,
        parentId,
        childId,
        alertType,
        title,
        body,
        data,
        timestamp,
        isRead,
        readAt,
        actionUrl,
      ];

  NotificationEntity copyWith({
    String? id,
    String? parentId,
    String? childId,
    AlertType? alertType,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    String? actionUrl,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      alertType: alertType ?? this.alertType,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

