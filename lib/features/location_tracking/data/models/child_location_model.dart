import 'package:json_annotation/json_annotation.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/child_location_entity.dart';

part 'child_location_model.g.dart';

@JsonSerializable()
class ChildLocationModel extends ChildLocationEntity {
  const ChildLocationModel({
    required super.childId,
    required super.latitude,
    required super.longitude,
    required super.accuracy,
    super.speed,
    required super.timestamp,
    required super.source,
    super.isActive,
  });

  factory ChildLocationModel.fromJson(Map<String, dynamic> json) =>
      _$ChildLocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChildLocationModelToJson(this);

  factory ChildLocationModel.fromEntity(ChildLocationEntity entity) {
    return ChildLocationModel(
      childId: entity.childId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      speed: entity.speed,
      timestamp: entity.timestamp,
      source: entity.source,
      isActive: entity.isActive,
    );
  }

  ChildLocationEntity toEntity() {
    return ChildLocationEntity(
      childId: childId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      speed: speed,
      timestamp: timestamp,
      source: source,
      isActive: isActive,
    );
  }

  factory ChildLocationModel.fromFirestore(
    Map<String, dynamic> data,
    String childId,
  ) {
    return ChildLocationModel(
      childId: childId,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      accuracy: (data['accuracy'] as num).toDouble(),
      speed: data['speed'] != null ? (data['speed'] as num).toDouble() : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
      source: data['source'] as String? ?? 'gps',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'source': source,
      'isActive': isActive,
    };
  }
}