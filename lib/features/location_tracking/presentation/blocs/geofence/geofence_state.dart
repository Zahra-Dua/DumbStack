part of 'geofence_bloc.dart';

class GeofenceState extends Equatable {
  final bool isLoading;
  final bool isValid;
  final String? error;
  final String? validationError;
  final GeofenceZoneEntity? createdZone;
  final GeofenceZoneEntity? updatedZone;
  final String? deletedZoneId;
  final ChildLocationEntity? childLocation;
  final double? selectedLatitude;
  final double? selectedLongitude;
  final double? selectedRadius;
  final String? selectedName;

  const GeofenceState({
    this.isLoading = false,
    this.isValid = false,
    this.error,
    this.validationError,
    this.createdZone,
    this.updatedZone,
    this.deletedZoneId,
    this.childLocation,
    this.selectedLatitude,
    this.selectedLongitude,
    this.selectedRadius,
    this.selectedName,
  });

  GeofenceState copyWith({
    bool? isLoading,
    bool? isValid,
    String? error,
    String? validationError,
    GeofenceZoneEntity? createdZone,
    GeofenceZoneEntity? updatedZone,
    String? deletedZoneId,
    ChildLocationEntity? childLocation,
    double? selectedLatitude,
    double? selectedLongitude,
    double? selectedRadius,
    String? selectedName,
  }) {
    return GeofenceState(
      isLoading: isLoading ?? this.isLoading,
      isValid: isValid ?? this.isValid,
      error: error,
      validationError: validationError,
      createdZone: createdZone ?? this.createdZone,
      updatedZone: updatedZone ?? this.updatedZone,
      deletedZoneId: deletedZoneId ?? this.deletedZoneId,
      childLocation: childLocation ?? this.childLocation,
      selectedLatitude: selectedLatitude ?? this.selectedLatitude,
      selectedLongitude: selectedLongitude ?? this.selectedLongitude,
      selectedRadius: selectedRadius ?? this.selectedRadius,
      selectedName: selectedName ?? this.selectedName,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isValid,
        error,
        validationError,
        createdZone,
        updatedZone,
        deletedZoneId,
        childLocation,
        selectedLatitude,
        selectedLongitude,
        selectedRadius,
        selectedName,
      ];
}