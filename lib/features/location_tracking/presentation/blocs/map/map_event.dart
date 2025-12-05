part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class MapStartTracking extends MapEvent {
  final String childId;

  const MapStartTracking(this.childId);

  @override
  List<Object?> get props => [childId];
}

class MapStopTracking extends MapEvent {
  const MapStopTracking();
}

class MapLocationUpdated extends MapEvent {
  final ChildLocationEntity location;

  const MapLocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

class MapGeofencesUpdated extends MapEvent {
  final List<GeofenceZoneEntity> geofences;

  const MapGeofencesUpdated(this.geofences);

  @override
  List<Object?> get props => [geofences];
}

class MapLocationError extends MapEvent {
  final String message;

  const MapLocationError(this.message);

  @override
  List<Object?> get props => [message];
}

class MapGeofenceError extends MapEvent {
  final String message;

  const MapGeofenceError(this.message);

  @override
  List<Object?> get props => [message];
}