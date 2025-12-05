import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/geofence_zone_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/child_location_entity.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/set_geofence_usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/delete_geofence_usecase.dart';
import 'package:parental_control_app/features/location_tracking/domain/usecases/get_last_location_usecase.dart';

part 'geofence_event.dart';
part 'geofence_state.dart';

class GeofenceBloc extends Bloc<GeofenceEvent, GeofenceState> {
  final SetGeofenceUseCase setGeofenceUseCase;
  final DeleteGeofenceUseCase deleteGeofenceUseCase;
  final GetLastLocationUseCase getLastLocationUseCase;

  GeofenceBloc({
    required this.setGeofenceUseCase,
    required this.deleteGeofenceUseCase,
    required this.getLastLocationUseCase,
  }) : super(const GeofenceState()) {
    on<GeofenceCreateRequested>(_onCreateRequested);
    on<GeofenceUpdateRequested>(_onUpdateRequested);
    on<GeofenceDeleteRequested>(_onDeleteRequested);
    on<GeofenceValidationRequested>(_onValidationRequested);
    on<GeofenceLoadChildLocation>(_onLoadChildLocation);
    on<GeofenceZoneParametersChanged>(_onZoneParametersChanged);
    on<GeofenceReset>(_onReset);
  }

  Future<void> _onCreateRequested(
    GeofenceCreateRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final params = SetGeofenceParams(
      childId: event.childId,
      name: event.name,
      centerLatitude: event.centerLatitude,
      centerLongitude: event.centerLongitude,
      radiusMeters: event.radiusMeters,
      description: event.description,
      color: event.color,
    );

    final result = await setGeofenceUseCase(params);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (zone) => emit(state.copyWith(
        isLoading: false,
        createdZone: zone,
        error: null,
      )),
    );
  }

  Future<void> _onUpdateRequested(
    GeofenceUpdateRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final params = SetGeofenceParams(
      childId: event.zone.childId,
      name: event.zone.name,
      centerLatitude: event.zone.centerLatitude,
      centerLongitude: event.zone.centerLongitude,
      radiusMeters: event.zone.radiusMeters,
      description: event.zone.description,
      color: event.zone.color,
    );

    final result = await setGeofenceUseCase(params);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (zone) => emit(state.copyWith(
        isLoading: false,
        updatedZone: zone,
        error: null,
      )),
    );
  }

  Future<void> _onDeleteRequested(
    GeofenceDeleteRequested event,
    Emitter<GeofenceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await deleteGeofenceUseCase(event.zoneId);

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        deletedZoneId: event.zoneId,
        error: null,
      )),
    );
  }

  void _onValidationRequested(
    GeofenceValidationRequested event,
    Emitter<GeofenceState> emit,
  ) {
    // Basic client-side validation
    String? validationError;

    if (event.name.trim().isEmpty) {
      validationError = 'Zone name cannot be empty';
    } else if (event.radiusMeters < 50) {
      validationError = 'Minimum radius is 50 meters';
    } else if (event.radiusMeters > 10000) {
      validationError = 'Maximum radius is 10 kilometers';
    }

    emit(state.copyWith(
      validationError: validationError,
      isValid: validationError == null,
    ));
  }

  Future<void> _onLoadChildLocation(
    GeofenceLoadChildLocation event,
    Emitter<GeofenceState> emit,
  ) async {
    final result = await getLastLocationUseCase(event.childId);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (location) => emit(state.copyWith(childLocation: location)),
    );
  }

  void _onZoneParametersChanged(
    GeofenceZoneParametersChanged event,
    Emitter<GeofenceState> emit,
  ) {
    emit(state.copyWith(
      selectedLatitude: event.latitude,
      selectedLongitude: event.longitude,
      selectedRadius: event.radius,
      selectedName: event.name,
      validationError: null,
    ));
  }

  void _onReset(GeofenceReset event, Emitter<GeofenceState> emit) {
    emit(const GeofenceState());
  }
}