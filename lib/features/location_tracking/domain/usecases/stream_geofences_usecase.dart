import 'package:dartz/dartz.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import 'package:parental_control_app/core/usecase/usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/geofence_zone_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/repositories/geofence_repository.dart';

class StreamGeofencesUseCase implements StreamUseCase<List<GeofenceZoneEntity>, String> {
  final GeofenceRepository repository;

  StreamGeofencesUseCase(this.repository);

  @override
  Stream<Either<Failure, List<GeofenceZoneEntity>>> call(String childId) {
    return repository.streamGeofenceZones(childId);
  }
}