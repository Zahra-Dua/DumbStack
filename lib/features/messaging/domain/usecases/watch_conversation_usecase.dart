import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class WatchConversationUseCase {
  final MessageRepository repository;
  WatchConversationUseCase(this.repository);

  Stream<Either<Failure, List<MessageEntity>>> call(Params params) {
    return repository.watchConversation(params.conversationId);
  }
}

class Params extends Equatable {
  final String conversationId;
  const Params(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}


