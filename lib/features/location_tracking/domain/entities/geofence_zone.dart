class GeofenceZone {
  final String id;
  final String name;
  final double centerLat;
  final double centerLng;
  final double radiusMeters;
  final bool active;

  const GeofenceZone({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
    required this.active,
  });
}