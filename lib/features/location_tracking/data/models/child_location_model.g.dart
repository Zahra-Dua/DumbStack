// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChildLocationModel _$ChildLocationModelFromJson(Map<String, dynamic> json) =>
    ChildLocationModel(
      childId: json['childId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$ChildLocationModelToJson(ChildLocationModel instance) =>
    <String, dynamic>{
      'childId': instance.childId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'speed': instance.speed,
      'timestamp': instance.timestamp.toIso8601String(),
      'source': instance.source,
      'isActive': instance.isActive,
    };
