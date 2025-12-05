class ZoneEvent {
  final String id;
  final String zoneId;
  final String type; // enter | exit
  final DateTime occurredAt;

  const ZoneEvent({
    required this.id,
    required this.zoneId,
    required this.type,
    required this.occurredAt,
  });
}