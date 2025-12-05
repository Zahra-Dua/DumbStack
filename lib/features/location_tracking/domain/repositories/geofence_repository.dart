import 'package:dartz/dartz.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/geofence_zone_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/zone_event_entity.dart';

abstract class GeofenceRepository {
  /// Create a new geofence zone for a child
  /// Returns Either<Failure, GeofenceZoneEntity>
  Future<Either<Failure, GeofenceZoneEntity>> createGeofenceZone(GeofenceZoneEntity zone);

  /// Get all geofence zones for a specific child
  /// Returns Either<Failure, List<GeofenceZoneEntity>>
  Future<Either<Failure, List<GeofenceZoneEntity>>> getGeofenceZones(String childId);

  /// Stream geofence zones for real-time updates
  /// Returns a stream of Either<Failure, List<GeofenceZoneEntity>>
  Stream<Either<Failure, List<GeofenceZoneEntity>>> streamGeofenceZones(String childId);

  /// Update an existing geofence zone
  /// Returns Either<Failure, GeofenceZoneEntity>
  Future<Either<Failure, GeofenceZoneEntity>> updateGeofenceZone(GeofenceZoneEntity zone);

  /// Delete a geofence zone
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> deleteGeofenceZone(String zoneId);

  /// Validate if a geofence zone is within acceptable limits
  /// Returns Either<Failure, bool>
  Future<Either<Failure, bool>> validateGeofenceZone(GeofenceZoneEntity zone);

  /// Create a zone event (entry/exit)
  /// Returns Either<Failure, ZoneEventEntity>
  Future<Either<Failure, ZoneEventEntity>> createZoneEvent(ZoneEventEntity event);

  /// Stream zone events for notifications
  /// Returns a stream of Either<Failure, List<ZoneEventEntity>>
  Stream<Either<Failure, List<ZoneEventEntity>>> streamZoneEvents(String childId);

  /// Get zone event history
  /// Returns Either<Failure, List<ZoneEventEntity>>
  Future<Either<Failure, List<ZoneEventEntity>>> getZoneEventHistory({
    required String childId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Mark zone event as notified
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> markEventAsNotified(String eventId);
}