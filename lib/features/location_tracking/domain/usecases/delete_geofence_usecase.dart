import 'package:dartz/dartz.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import 'package:parental_control_app/core/usecase/usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/repositories/geofence_repository.dart';

class DeleteGeofenceUseCase implements UseCase<void, String> {
  final GeofenceRepository repository;

  DeleteGeofenceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String zoneId) {
    return repository.deleteGeofenceZone(zoneId);
  }
}