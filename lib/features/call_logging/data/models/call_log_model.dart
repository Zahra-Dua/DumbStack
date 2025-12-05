import 'package:call_log/call_log.dart';

class CallLogModel {
  final String id;
  final String? name;
  final String number;
  final String? simDisplayName;
  final int duration;
  final DateTime dateTime;
  final CallType type;
  final String childId;
  final String parentId;
  final DateTime uploadedAt;

  CallLogModel({
    required this.id,
    this.name,
    required this.number,
    this.simDisplayName,
    required this.duration,
    required this.dateTime,
    required this.type,
    required this.childId,
    required this.parentId,
    required this.uploadedAt,
  });

  factory CallLogModel.fromCallLogEntry({
    required CallLogEntry entry,
    required String childId,
    required String parentId,
  }) {
    return CallLogModel(
      id: entry.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: entry.name,
      number: entry.number ?? 'Unknown',
      simDisplayName: entry.simDisplayName,
      duration: entry.duration ?? 0,
      dateTime: DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0),
      type: entry.callType ?? CallType.outgoing,
      childId: childId,
      parentId: parentId,
      uploadedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'simDisplayName': simDisplayName,
      'duration': duration,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'type': type.toString(),
      'childId': childId,
      'parentId': parentId,
      'uploadedAt': uploadedAt.millisecondsSinceEpoch,
    };
  }

  factory CallLogModel.fromMap(Map<String, dynamic> map) {
    return CallLogModel(
      id: map['id'] ?? '',
      name: map['name'],
      number: map['number'] ?? 'Unknown',
      simDisplayName: map['simDisplayName'],
      duration: map['duration'] ?? 0,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime'] ?? 0),
      type: CallType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => CallType.outgoing,
      ),
      childId: map['childId'] ?? '',
      parentId: map['parentId'] ?? '',
      uploadedAt: DateTime.fromMillisecondsSinceEpoch(map['uploadedAt'] ?? 0),
    );
  }

  String get callTypeString {
    switch (type) {
      case CallType.incoming:
        return 'Incoming';
      case CallType.outgoing:
        return 'Outgoing';
      case CallType.missed:
        return 'Missed';
      case CallType.rejected:
        return 'Rejected';
      case CallType.blocked:
        return 'Blocked';
      case CallType.answeredExternally:
        return 'Answered Externally';
      default:
        return 'Unknown';
    }
  }

  String get durationString {
    if (duration < 60) {
      return '${duration}s';
    } else if (duration < 3600) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = duration ~/ 3600;
      final minutes = (duration % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}
