part of 'geofence_bloc.dart';

abstract class GeofenceEvent extends Equatable {
  const GeofenceEvent();

  @override
  List<Object?> get props => [];
}

class GeofenceCreateRequested extends GeofenceEvent {
  final String childId;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final String? description;
  final String? color;

  const GeofenceCreateRequested({
    required this.childId,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    this.description,
    this.color,
  });

  @override
  List<Object?> get props => [
        childId,
        name,
        centerLatitude,
        centerLongitude,
        radiusMeters,
        description,
        color,
      ];
}

class GeofenceUpdateRequested extends GeofenceEvent {
  final GeofenceZoneEntity zone;

  const GeofenceUpdateRequested(this.zone);

  @override
  List<Object?> get props => [zone];
}

class GeofenceDeleteRequested extends GeofenceEvent {
  final String zoneId;

  const GeofenceDeleteRequested(this.zoneId);

  @override
  List<Object?> get props => [zoneId];
}

class GeofenceValidationRequested extends GeofenceEvent {
  final String name;
  final double radiusMeters;

  const GeofenceValidationRequested({
    required this.name,
    required this.radiusMeters,
  });

  @override
  List<Object?> get props => [name, radiusMeters];
}

class GeofenceLoadChildLocation extends GeofenceEvent {
  final String childId;

  const GeofenceLoadChildLocation(this.childId);

  @override
  List<Object?> get props => [childId];
}

class GeofenceZoneParametersChanged extends GeofenceEvent {
  final double? latitude;
  final double? longitude;
  final double? radius;
  final String? name;

  const GeofenceZoneParametersChanged({
    this.latitude,
    this.longitude,
    this.radius,
    this.name,
  });

  @override
  List<Object?> get props => [latitude, longitude, radius, name];
}

class GeofenceReset extends GeofenceEvent {
  const GeofenceReset();
}