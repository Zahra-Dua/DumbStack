// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zone_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZoneEventModel _$ZoneEventModelFromJson(Map<String, dynamic> json) =>
    ZoneEventModel(
      id: json['id'] as String,
      childId: json['childId'] as String,
      zoneId: json['zoneId'] as String,
      zoneName: json['zoneName'] as String,
      eventType: $enumDecode(_$ZoneEventTypeEnumMap, json['eventType']),
      childLatitude: (json['childLatitude'] as num).toDouble(),
      childLongitude: (json['childLongitude'] as num).toDouble(),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      isNotified: json['isNotified'] as bool? ?? false,
      deviceSource: json['deviceSource'] as String? ?? 'server',
    );

Map<String, dynamic> _$ZoneEventModelToJson(ZoneEventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'childId': instance.childId,
      'zoneId': instance.zoneId,
      'zoneName': instance.zoneName,
      'eventType': _$ZoneEventTypeEnumMap[instance.eventType]!,
      'childLatitude': instance.childLatitude,
      'childLongitude': instance.childLongitude,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'isNotified': instance.isNotified,
      'deviceSource': instance.deviceSource,
    };

const _$ZoneEventTypeEnumMap = {
  ZoneEventType.enter: 'enter',
  ZoneEventType.exit: 'exit',
};
