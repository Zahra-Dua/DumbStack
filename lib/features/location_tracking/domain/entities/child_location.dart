class ChildLocation {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double? speedMetersPerSecond;
  final DateTime timestamp;
  final String source; // device, manual, etc.

  const ChildLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    required this.source,
    this.speedMetersPerSecond,
  });
}