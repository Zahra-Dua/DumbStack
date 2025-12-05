import 'package:equatable/equatable.dart';

enum ZoneEventType { enter, exit }

class ZoneEventEntity extends Equatable {
  final String id;
  final String childId;
  final String zoneId;
  final String zoneName;
  final ZoneEventType eventType;
  final double childLatitude;
  final double childLongitude;
  final DateTime occurredAt;
  final bool isNotified;
  final String? deviceSource; // 'device' or 'server'

  const ZoneEventEntity({
    required this.id,
    required this.childId,
    required this.zoneId,
    required this.zoneName,
    required this.eventType,
    required this.childLatitude,
    required this.childLongitude,
    required this.occurredAt,
    this.isNotified = false,
    this.deviceSource = 'server',
  });

  @override
  List<Object?> get props => [
        id,
        childId,
        zoneId,
        zoneName,
        eventType,
        childLatitude,
        childLongitude,
        occurredAt,
        isNotified,
        deviceSource,
      ];

  ZoneEventEntity copyWith({
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
    return ZoneEventEntity(
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

  // Helper method to get user-friendly event message
  String getEventMessage() {
    final action = eventType == ZoneEventType.enter ? 'entered' : 'left';
    return 'Child has $action $zoneName';
  }

  // Helper method to get event icon based on type
  String getEventIcon() {
    return eventType == ZoneEventType.enter ? '🟢' : '🔴';
  }
}
