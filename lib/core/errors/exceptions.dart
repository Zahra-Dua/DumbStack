/// Base exception class for all custom exceptions
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Server-related exceptions
class ServerException extends AppException {
  const ServerException(super.message);
}

/// Cache/Local storage related exceptions
class CacheException extends AppException {
  const CacheException(super.message);
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Authentication related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(super.message);
}

/// Authorization related exceptions
class AuthorizationException extends AppException {
  const AuthorizationException(super.message);
}

/// Location service related exceptions
class LocationException extends AppException {
  const LocationException(super.message);
}

/// Geofencing related exceptions
class GeofenceException extends AppException {
  const GeofenceException(super.message);
}

/// Validation related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Device related exceptions
class DeviceException extends AppException {
  const DeviceException(super.message);
}
