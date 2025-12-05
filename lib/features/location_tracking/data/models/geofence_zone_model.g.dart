// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geofence_zone_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeofenceZoneModel _$GeofenceZoneModelFromJson(Map<String, dynamic> json) =>
    GeofenceZoneModel(
      id: json['id'] as String,
      childId: json['childId'] as String,
      name: json['name'] as String,
      centerLatitude: (json['centerLatitude'] as num).toDouble(),
      centerLongitude: (json['centerLongitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#4A90E2',
    );

Map<String, dynamic> _$GeofenceZoneModelToJson(GeofenceZoneModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'childId': instance.childId,
      'name': instance.name,
      'centerLatitude': instance.centerLatitude,
      'centerLongitude': instance.centerLongitude,
      'radiusMeters': instance.radiusMeters,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'description': instance.description,
      'color': instance.color,
    };
