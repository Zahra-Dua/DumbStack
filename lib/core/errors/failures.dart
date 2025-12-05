import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  final Object? error;
  final StackTrace? stackTrace;
  
  const ServerFailure(super.message, {this.error, this.stackTrace});
}

class CacheFailure extends Failure {
  final Object? error;
  final StackTrace? stackTrace;
  
  const CacheFailure(super.message, {this.error, this.stackTrace});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends Failure {
  final Object? error;
  final StackTrace? stackTrace;
  
  const UnknownFailure(super.message, {this.error, this.stackTrace});
}

// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message);
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message);
}

// Location specific failures
class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure() : super('Location services are disabled on the child\'s device. Please check the device settings.');
}

class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure() : super('Location permission is denied. Please enable location access.');
}

class GeofenceValidationFailure extends Failure {
  const GeofenceValidationFailure(super.message);
}

// Device specific failures
class DeviceNotFoundFailure extends Failure {
  const DeviceNotFoundFailure(super.message);
}

class DeviceOfflineFailure extends Failure {
  const DeviceOfflineFailure() : super('Child device is currently offline.');
}
