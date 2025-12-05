import 'dart:math';
import 'package:equatable/equatable.dart';

class GeofenceZoneEntity extends Equatable {
  final String id;
  final String childId;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? description;
  final String color; // For UI customization

  const GeofenceZoneEntity({
    required this.id,
    required this.childId,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.description,
    this.color = '#4A90E2', // Default blue color
  });

  @override
  List<Object?> get props => [
        id,
        childId,
        name,
        centerLatitude,
        centerLongitude,
        radiusMeters,
        isActive,
        createdAt,
        updatedAt,
        description,
        color,
      ];

  GeofenceZoneEntity copyWith({
    String? id,
    String? childId,
    String? name,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusMeters,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? color,
  }) {
    return GeofenceZoneEntity(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      name: name ?? this.name,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

  // Helper method to check if a location is within this geofence
  bool containsLocation(double latitude, double longitude) {
    final distance = _calculateDistance(
      centerLatitude,
      centerLongitude,
      latitude,
      longitude,
    );
    return distance <= radiusMeters;
  }

  // Check if child has exited the geofence boundary
  bool hasExitedGeofence(double latitude, double longitude) {
    final distance = _calculateDistance(
      centerLatitude,
      centerLongitude,
      latitude,
      longitude,
    );
    return distance > radiusMeters;
  }

  // Get distance from geofence center
  double getDistanceFromCenter(double latitude, double longitude) {
    return _calculateDistance(
      centerLatitude,
      centerLongitude,
      latitude,
      longitude,
    );
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }
}
