import 'package:dartz/dartz.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/child_location_entity.dart';

abstract class LocationRepository {
  /// Stream real-time location updates for a specific child
  /// Returns a stream of Either<Failure, ChildLocationEntity>
  Stream<Either<Failure, ChildLocationEntity>> streamChildLocation(String childId);

  /// Get the last known location for a child
  /// Returns Either<Failure, ChildLocationEntity?>
  Future<Either<Failure, ChildLocationEntity?>> getLastKnownLocation(String childId);

  /// Update child's location (typically called from child device)
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> updateChildLocation(ChildLocationEntity location);

  /// Check if location services are enabled on child device
  /// Returns Either<Failure, bool>
  Future<Either<Failure, bool>> checkLocationServicesStatus(String childId);

  /// Get location history for a child within a date range
  /// Returns Either<Failure, List<ChildLocationEntity>>
  Future<Either<Failure, List<ChildLocationEntity>>> getLocationHistory({
    required String childId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Stop location tracking for a child
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> stopLocationTracking(String childId);
}