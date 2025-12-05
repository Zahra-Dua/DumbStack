import 'package:dartz/dartz.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import 'package:parental_control_app/core/errors/exceptions.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/geofence_zone_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/zone_event_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/repositories/geofence_repository.dart';
import 'package:parental_control_app/features/location_tracking/data/datasources/geofence_remote_datasource.dart';
import 'package:parental_control_app/features/location_tracking/data/models/geofence_zone_model.dart';
import 'package:parental_control_app/features/location_tracking/data/models/zone_event_model.dart';

class GeofenceRepositoryImpl implements GeofenceRepository {
  final GeofenceRemoteDataSource remote;

  GeofenceRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, GeofenceZoneEntity>> createGeofenceZone(GeofenceZoneEntity zone) async {
    try {
      final zoneModel = GeofenceZoneModel.fromEntity(zone);
      final createdZone = await remote.createGeofenceZone(zoneModel);
      return Right(createdZone.toEntity());
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to create geofence zone: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<GeofenceZoneEntity>>> getGeofenceZones(String childId) async {
    try {
      final zones = await remote.getGeofenceZones(childId);
      final entities = zones.map((zone) => zone.toEntity()).toList();
      return Right(entities);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to get geofence zones: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, List<GeofenceZoneEntity>>> streamGeofenceZones(String childId) {
    return remote.streamGeofenceZones(childId).map(
      (zones) {
        final entities = zones.map((zone) => zone.toEntity()).toList();
        return Right(entities) as Either<Failure, List<GeofenceZoneEntity>>;
      },
    ).handleError((error) {
      return Left(_mapExceptionToFailure(error));
    });
  }

  @override
  Future<Either<Failure, GeofenceZoneEntity>> updateGeofenceZone(GeofenceZoneEntity zone) async {
    try {
      final zoneModel = GeofenceZoneModel.fromEntity(zone);
      final updatedZone = await remote.updateGeofenceZone(zoneModel);
      return Right(updatedZone.toEntity());
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to update geofence zone: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGeofenceZone(String zoneId) async {
    try {
      await remote.deleteGeofenceZone(zoneId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to delete geofence zone: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateGeofenceZone(GeofenceZoneEntity zone) async {
    try {
      final zoneModel = GeofenceZoneModel.fromEntity(zone);
      final isValid = await remote.validateGeofenceZone(zoneModel);
      return Right(isValid);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ValidationFailure('Failed to validate geofence zone: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ZoneEventEntity>> createZoneEvent(ZoneEventEntity event) async {
    try {
      final eventModel = ZoneEventModel.fromEntity(event);
      final createdEvent = await remote.createZoneEvent(eventModel);
      return Right(createdEvent.toEntity());
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to create zone event: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, List<ZoneEventEntity>>> streamZoneEvents(String childId) {
    return remote.streamZoneEvents(childId).map(
      (events) {
        final entities = events.map((event) => event.toEntity()).toList();
        return Right(entities) as Either<Failure, List<ZoneEventEntity>>;
      },
    ).handleError((error) {
      return Left(_mapExceptionToFailure(error));
    });
  }

  @override
  Future<Either<Failure, List<ZoneEventEntity>>> getZoneEventHistory({
    required String childId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final events = await remote.getZoneEventHistory(
        childId: childId,
        startDate: startDate,
        endDate: endDate,
      );
      final entities = events.map((event) => event.toEntity()).toList();
      return Right(entities);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to get zone event history: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markEventAsNotified(String eventId) async {
    try {
      await remote.markEventAsNotified(eventId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to mark event as notified: ${e.toString()}'));
    }
  }

  /// Maps exceptions to appropriate failure types
  Failure _mapExceptionToFailure(Exception exception) {
    if (exception is ServerException) {
      return ServerFailure(exception.message);
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else if (exception is GeofenceException) {
      return GeofenceValidationFailure(exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message);
    } else if (exception is AuthenticationException) {
      return AuthenticationFailure(exception.message);
    } else if (exception is AuthorizationException) {
      return AuthorizationFailure(exception.message);
    }
    
    return ServerFailure('An unexpected error occurred');
  }
}