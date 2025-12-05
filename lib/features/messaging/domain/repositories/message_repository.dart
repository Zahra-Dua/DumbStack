import 'package:dartz/dartz.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import '../entities/message_entity.dart';

abstract class MessageRepository {
  Future<Either<Failure, Unit>> sendMessage(MessageEntity message);
  Stream<Either<Failure, List<MessageEntity>>> watchConversation(String conversationId);
}


