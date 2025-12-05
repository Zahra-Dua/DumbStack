import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class StreamNotificationsUseCase {
  final NotificationRepository repository;

  StreamNotificationsUseCase(this.repository);

  Stream<Either<Failure, List<NotificationEntity>>> call(String parentId, {String? childId}) {
    return repository.streamNotifications(parentId, childId: childId);
  }
}

