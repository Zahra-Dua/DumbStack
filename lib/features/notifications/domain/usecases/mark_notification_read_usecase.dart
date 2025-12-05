import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationReadUseCase {
  final NotificationRepository repository;

  MarkNotificationReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String parentId, String childId, String notificationId) async {
    return await repository.markAsRead(parentId, childId, notificationId);
  }
}

