import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failure, void>> saveNotification(NotificationEntity notification);
  Stream<Either<Failure, List<NotificationEntity>>> streamNotifications(String parentId, {String? childId});
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String parentId, {String? childId, int? limit});
  Future<Either<Failure, void>> markAsRead(String parentId, String childId, String notificationId);
  Future<Either<Failure, void>> markAllAsRead(String parentId, {String? childId});
  Future<Either<Failure, void>> deleteNotification(String parentId, String childId, String notificationId);
}

