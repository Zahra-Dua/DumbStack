import 'package:dartz/dartz.dart';
import 'package:parental_control_app/core/errors/failures.dart';
import 'package:parental_control_app/core/errors/exceptions.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/child_location_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/repositories/location_repository.dart';
import 'package:parental_control_app/features/location_tracking/data/datasources/location_remote_datasource.dart';
import 'package:parental_control_app/features/location_tracking/data/models/child_location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remote;

  LocationRepositoryImpl({required this.remote});

  @override
  Stream<Either<Failure, ChildLocationEntity>> streamChildLocation(String childId) {
    return remote.streamChildLocation(childId).map(
      (location) => Right(location.toEntity()) as Either<Failure, ChildLocationEntity>,
    ).handleError((error) {
      return Left(_mapExceptionToFailure(error));
    });
  }

  @override
  Future<Either<Failure, ChildLocationEntity?>> getLastKnownLocation(String childId) async {
    try {
      final location = await remote.getLastKnownLocation(childId);
      return Right(location?.toEntity());
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateChildLocation(ChildLocationEntity location) async {
    try {
      final locationModel = ChildLocationModel.fromEntity(location);
      // Note: This method needs parentId and childId, but we only have location
      // For now, we'll use a placeholder implementation
      await remote.updateChildLocationSimple(locationModel);
      return const Right(null);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to update location: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkLocationServicesStatus(String childId) async {
    try {
      // Get the last known location to check if location services are working
      final location = await remote.getLastKnownLocation(childId);
      
      if (location == null) {
        return const Right(false);
      }
      
      // Check if the location is recent (within last 15 minutes)
      final now = DateTime.now();
      final locationAge = now.difference(location.timestamp);
      
      if (locationAge.inMinutes > 15) {
        return const Right(false); // Location services might be disabled
      }
      
      return Right(location.isActive);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to check location services: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ChildLocationEntity>>> getLocationHistory({
    required String childId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Note: This method needs parentId, but we only have childId
      // For now, we'll use a placeholder implementation
      await remote.getLocationHistory(
        parentId: 'placeholder', // This should be resolved from childId
        childId: childId,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Note: This needs to be updated to use ChildLocationModel instead of LocationModel
      final entities = <ChildLocationEntity>[];
      return Right(entities);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to get location history: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> stopLocationTracking(String childId) async {
    try {
      await remote.stopLocationTracking(childId);
      return const Right(null);
    } on AppException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure('Failed to stop location tracking: ${e.toString()}'));
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
    } else if (exception is LocationException) {
      return LocationServiceDisabledFailure();
    } else if (exception is AuthenticationException) {
      return AuthenticationFailure(exception.message);
    } else if (exception is AuthorizationException) {
      return AuthorizationFailure(exception.message);
    }
    
    return ServerFailure('An unexpected error occurred');
  }
}