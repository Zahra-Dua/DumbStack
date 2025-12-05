part of 'map_bloc.dart';

class MapState extends Equatable {
  final bool isTracking;
  final String? currentChildId;
  final ChildLocationEntity? currentLocation;
  final List<GeofenceZoneEntity> geofences;
  final DateTime? lastUpdated;
  final String? error;

  const MapState({
    this.isTracking = false,
    this.currentChildId,
    this.currentLocation,
    this.geofences = const [],
    this.lastUpdated,
    this.error,
  });

  MapState copyWith({
    bool? isTracking,
    String? currentChildId,
    ChildLocationEntity? currentLocation,
    List<GeofenceZoneEntity>? geofences,
    DateTime? lastUpdated,
    String? error,
  }) {
    return MapState(
      isTracking: isTracking ?? this.isTracking,
      currentChildId: currentChildId ?? this.currentChildId,
      currentLocation: currentLocation ?? this.currentLocation,
      geofences: geofences ?? this.geofences,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isTracking,
        currentChildId,
        currentLocation,
        geofences,
        lastUpdated,
        error,
      ];
}