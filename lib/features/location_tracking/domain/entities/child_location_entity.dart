import 'package:equatable/equatable.dart';

class ChildLocationEntity extends Equatable {
  final String childId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final DateTime timestamp;
  final String source; // 'gps' or 'network'
  final bool isActive;

  const ChildLocationEntity({
    required this.childId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    required this.timestamp,
    required this.source,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        childId,
        latitude,
        longitude,
        accuracy,
        speed,
        timestamp,
        source,
        isActive,
      ];

  ChildLocationEntity copyWith({
    String? childId,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    DateTime? timestamp,
    String? source,
    bool? isActive,
  }) {
    return ChildLocationEntity(
      childId: childId ?? this.childId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      isActive: isActive ?? this.isActive,
    );
  }
}
