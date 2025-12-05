import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/child_location_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/geofence_zone_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/stream_child_location_usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/stream_geofences_usecase.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final StreamChildLocationUseCase streamChildLocationUseCase;
  final StreamGeofencesUseCase streamGeofencesUseCase;

  MapBloc({
    required this.streamChildLocationUseCase,
    required this.streamGeofencesUseCase,
  }) : super(const MapState()) {
    on<MapStartTracking>(_onStartTracking);
    on<MapStopTracking>(_onStopTracking);
    on<MapLocationUpdated>(_onLocationUpdated);
    on<MapGeofencesUpdated>(_onGeofencesUpdated);
    on<MapLocationError>(_onLocationError);
    on<MapGeofenceError>(_onGeofenceError);
  }

  void _onStartTracking(MapStartTracking event, Emitter<MapState> emit) {
    emit(state.copyWith(
      isTracking: true,
      currentChildId: event.childId,
      error: null,
    ));

    // Start streaming location updates
    streamChildLocationUseCase(event.childId).listen(
      (result) {
        result.fold(
          (failure) => add(MapLocationError(failure.message)),
          (location) => add(MapLocationUpdated(location)),
        );
      },
    );

    // Start streaming geofence updates
    streamGeofencesUseCase(event.childId).listen(
      (result) {
        result.fold(
          (failure) => add(MapGeofenceError(failure.message)),
          (geofences) => add(MapGeofencesUpdated(geofences)),
        );
      },
    );
  }

  void _onStopTracking(MapStopTracking event, Emitter<MapState> emit) {
    emit(state.copyWith(
      isTracking: false,
      currentLocation: null,
      geofences: [],
      error: null,
    ));
  }

  void _onLocationUpdated(MapLocationUpdated event, Emitter<MapState> emit) {
    emit(state.copyWith(
      currentLocation: event.location,
      lastUpdated: DateTime.now(),
      error: null,
    ));
  }

  void _onGeofencesUpdated(MapGeofencesUpdated event, Emitter<MapState> emit) {
    emit(state.copyWith(
      geofences: event.geofences,
      error: null,
    ));
  }

  void _onLocationError(MapLocationError event, Emitter<MapState> emit) {
    emit(state.copyWith(
      error: event.message,
      isTracking: false,
    ));
  }

  void _onGeofenceError(MapGeofenceError event, Emitter<MapState> emit) {
    emit(state.copyWith(
      error: event.message,
    ));
  }
}