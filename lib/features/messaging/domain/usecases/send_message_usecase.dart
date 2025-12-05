import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class SendMessageUseCase {
  final MessageRepository repository;
  SendMessageUseCase(this.repository);

  Future<Either<Failure, Unit>> call(Params params) {
    return repository.sendMessage(params.message);
  }
}

class Params extends Equatable {
  final MessageEntity message;
  const Params(this.message);

  @override
  List<Object?> get props => [message];
}


