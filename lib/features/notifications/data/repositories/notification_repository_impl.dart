import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> saveNotification(NotificationEntity notification) async {
    try {
      await remoteDataSource.saveNotification(
        NotificationModel.fromEntity(notification),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<NotificationEntity>>> streamNotifications(String parentId, {String? childId}) {
    try {
      print('📡 [NotificationRepo] Starting stream for parent: $parentId, child: $childId');
      return remoteDataSource.streamNotifications(parentId, childId: childId)
          .map<Either<Failure, List<NotificationEntity>>>(
            (notifications) {
              print('📡 [NotificationRepo] Received ${notifications.length} notifications');
              return Right<Failure, List<NotificationEntity>>(notifications);
            },
          )
          .handleError((error, stackTrace) {
            print('❌ [NotificationRepo] Stream error: $error');
            print('❌ [NotificationRepo] Stack trace: $stackTrace');
            return Left<Failure, List<NotificationEntity>>(ServerFailure(error.toString()));
          });
    } catch (e) {
      print('❌ [NotificationRepo] Exception in streamNotifications: $e');
      return Stream.value(Left<Failure, List<NotificationEntity>>(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications(String parentId, {String? childId, int? limit}) async {
    try {
      final notifications = await remoteDataSource.getNotifications(parentId, childId: childId, limit: limit);
      return Right(notifications.map((n) => n as NotificationEntity).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String parentId, String childId, String notificationId) async {
    try {
      await remoteDataSource.markAsRead(parentId, childId, notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String parentId, {String? childId}) async {
    try {
      await remoteDataSource.markAllAsRead(parentId, childId: childId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String parentId, String childId, String notificationId) async {
    try {
      await remoteDataSource.deleteNotification(parentId, childId, notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

