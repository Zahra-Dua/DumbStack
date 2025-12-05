import 'package:json_annotation/json_annotation.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/geofence_zone_entity.dart';

part 'geofence_zone_model.g.dart';

@JsonSerializable()
class GeofenceZoneModel extends GeofenceZoneEntity {
  const GeofenceZoneModel({
    required super.id,
    required super.childId,
    required super.name,
    required super.centerLatitude,
    required super.centerLongitude,
    required super.radiusMeters,
    super.isActive,
    required super.createdAt,
    super.updatedAt,
    super.description,
    super.color,
  });

  factory GeofenceZoneModel.fromJson(Map<String, dynamic> json) =>
      _$GeofenceZoneModelFromJson(json);

  Map<String, dynamic> toJson() => _$GeofenceZoneModelToJson(this);

  factory GeofenceZoneModel.fromEntity(GeofenceZoneEntity entity) {
    return GeofenceZoneModel(
      id: entity.id,
      childId: entity.childId,
      name: entity.name,
      centerLatitude: entity.centerLatitude,
      centerLongitude: entity.centerLongitude,
      radiusMeters: entity.radiusMeters,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      description: entity.description,
      color: entity.color,
    );
  }

  GeofenceZoneEntity toEntity() {
    return GeofenceZoneEntity(
      id: id,
      childId: childId,
      name: name,
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      radiusMeters: radiusMeters,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      description: description,
      color: color,
    );
  }

  factory GeofenceZoneModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return GeofenceZoneModel(
      id: documentId,
      childId: data['childId'] as String,
      name: data['name'] as String,
      centerLatitude: (data['centerLatitude'] as num).toDouble(),
      centerLongitude: (data['centerLongitude'] as num).toDouble(),
      radiusMeters: (data['radiusMeters'] as num).toDouble(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
          : null,
      description: data['description'] as String?,
      color: data['color'] as String? ?? '#4A90E2',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'name': name,
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'radiusMeters': radiusMeters,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'description': description,
      'color': color,
    };
  }

  @override
  GeofenceZoneModel copyWith({
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
    return GeofenceZoneModel(
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
}