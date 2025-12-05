import 'package:json_annotation/json_annotation.dart';
import 'package:parental_control_app/features/location_tracking/domain/entities/zone_event_entity.dart';

part 'zone_event_model.g.dart';

@JsonSerializable()
class ZoneEventModel extends ZoneEventEntity {
  const ZoneEventModel({
    required super.id,
    required super.childId,
    required super.zoneId,
    required super.zoneName,
    required super.eventType,
    required super.childLatitude,
    required super.childLongitude,
    required super.occurredAt,
    super.isNotified,
    super.deviceSource,
  });

  factory ZoneEventModel.fromJson(Map<String, dynamic> json) =>
      _$ZoneEventModelFromJson(json);

  Map<String, dynamic> toJson() => _$ZoneEventModelToJson(this);

  factory ZoneEventModel.fromEntity(ZoneEventEntity entity) {
    return ZoneEventModel(
      id: entity.id,
      childId: entity.childId,
      zoneId: entity.zoneId,
      zoneName: entity.zoneName,
      eventType: entity.eventType,
      childLatitude: entity.childLatitude,
      childLongitude: entity.childLongitude,
      occurredAt: entity.occurredAt,
      isNotified: entity.isNotified,
      deviceSource: entity.deviceSource,
    );
  }

  ZoneEventEntity toEntity() {
    return ZoneEventEntity(
      id: id,
      childId: childId,
      zoneId: zoneId,
      zoneName: zoneName,
      eventType: eventType,
      childLatitude: childLatitude,
      childLongitude: childLongitude,
      occurredAt: occurredAt,
      isNotified: isNotified,
      deviceSource: deviceSource,
    );
  }

  factory ZoneEventModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return ZoneEventModel(
      id: documentId,
      childId: data['childId'] as String,
      zoneId: data['zoneId'] as String,
      zoneName: data['zoneName'] as String,
      eventType: ZoneEventType.values.firstWhere(
        (e) => e.toString().split('.').last == data['eventType'],
      ),
      childLatitude: (data['childLatitude'] as num).toDouble(),
      childLongitude: (data['childLongitude'] as num).toDouble(),
      occurredAt: DateTime.fromMillisecondsSinceEpoch(data['occurredAt'] as int),
      isNotified: data['isNotified'] as bool? ?? false,
      deviceSource: data['deviceSource'] as String? ?? 'server',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'zoneId': zoneId,
      'zoneName': zoneName,
      'eventType': eventType.toString().split('.').last,
      'childLatitude': childLatitude,
      'childLongitude': childLongitude,
      'occurredAt': occurredAt.millisecondsSinceEpoch,
      'isNotified': isNotified,
      'deviceSource': deviceSource,
    };
  }

  @override
  ZoneEventModel copyWith({
    String? id,
    String? childId,
    String? zoneId,
    String? zoneName,
    ZoneEventType? eventType,
    double? childLatitude,
    double? childLongitude,
    DateTime? occurredAt,
    bool? isNotified,
    String? deviceSource,
  }) {
    return ZoneEventModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      zoneId: zoneId ?? this.zoneId,
      zoneName: zoneName ?? this.zoneName,
      eventType: eventType ?? this.eventType,
      childLatitude: childLatitude ?? this.childLatitude,
      childLongitude: childLongitude ?? this.childLongitude,
      occurredAt: occurredAt ?? this.occurredAt,
      isNotified: isNotified ?? this.isNotified,
      deviceSource: deviceSource ?? this.deviceSource,
    );
  }
}