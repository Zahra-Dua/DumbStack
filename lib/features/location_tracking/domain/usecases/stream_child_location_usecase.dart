import 'package:dartz/dartz.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import 'package:parental_control_app/core/usecase/usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/child_location_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/repositories/location_repository.dart';

class StreamChildLocationUseCase implements StreamUseCase<ChildLocationEntity, String> {
  final LocationRepository repository;

  StreamChildLocationUseCase(this.repository);

  @override
  Stream<Either<Failure, ChildLocationEntity>> call(String childId) {
    return repository.streamChildLocation(childId);
  }
}