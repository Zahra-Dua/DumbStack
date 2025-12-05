import 'package:dartz/dartz.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import 'package:parental_control_app/core/usecase/usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/zone_event_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/repositories/geofence_repository.dart';

class StreamZoneEventsUseCase implements StreamUseCase<List<ZoneEventEntity>, String> {
  final GeofenceRepository repository;

  StreamZoneEventsUseCase(this.repository);

  @override
  Stream<Either<Failure, List<ZoneEventEntity>>> call(String childId) {
    return repository.streamZoneEvents(childId);
  }
}