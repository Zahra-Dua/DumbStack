part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String parentId;
  final int? limit;

  const LoadNotifications(this.parentId, {this.limit});

  @override
  List<Object?> get props => [parentId, limit];
}

class StreamNotifications extends NotificationEvent {
  final String parentId;
  final String? childId;

  const StreamNotifications(this.parentId, {this.childId});

  @override
  List<Object?> get props => [parentId, childId];
}

class MarkAsRead extends NotificationEvent {
  final String parentId;
  final String childId;
  final String notificationId;

  const MarkAsRead(this.parentId, this.childId, this.notificationId);

  @override
  List<Object?> get props => [parentId, childId, notificationId];
}

class MarkAllAsRead extends NotificationEvent {
  final String parentId;

  const MarkAllAsRead(this.parentId);

  @override
  List<Object?> get props => [parentId];
}

