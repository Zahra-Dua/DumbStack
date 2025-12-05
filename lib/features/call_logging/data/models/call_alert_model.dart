import 'package:cloud_firestore/cloud_firestore.dart';

class CallAlertModel {
  final String alertId;
  final String childId;
  final String number;
  final String reason;
  final int duration;
  final DateTime timestamp;
  final String rule;
  final String callType;
  final int countLast24h;
  final DateTime createdAt;
  final String? contactName;
  final bool isFalsePositive;

  CallAlertModel({
    required this.alertId,
    required this.childId,
    required this.number,
    required this.reason,
    required this.duration,
    required this.timestamp,
    required this.rule,
    required this.callType,
    required this.countLast24h,
    required this.createdAt,
    this.contactName,
    this.isFalsePositive = false,
  });

  factory CallAlertModel.fromMap(Map<String, dynamic> map) {
    try {
      // Parse timestamp with better error handling
      DateTime parseTimestamp(dynamic timestamp) {
        if (timestamp == null) {
          print('⚠️ [CallAlertModel] Timestamp is null, using current time');
          return DateTime.now();
        }
        
        if (timestamp is Timestamp) {
          return timestamp.toDate();
        } else if (timestamp is String) {
          try {
            return DateTime.parse(timestamp);
          } catch (e) {
            print('⚠️ [CallAlertModel] Error parsing timestamp string: $e');
            return DateTime.now();
          }
        } else if (timestamp is int) {
          // Handle milliseconds since epoch
          if (timestamp > 1000000000000) {
            // Milliseconds
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          } else {
            // Seconds
            return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          }
        } else {
          print('⚠️ [CallAlertModel] Unknown timestamp type: ${timestamp.runtimeType}');
          return DateTime.now();
        }
      }
      
      // Parse createdAt with better error handling
      DateTime parseCreatedAt(dynamic createdAt) {
        if (createdAt == null) {
          return DateTime.now();
        }
        if (createdAt is Timestamp) {
          return createdAt.toDate();
        } else if (createdAt is String) {
          try {
            return DateTime.parse(createdAt);
          } catch (e) {
            return DateTime.now();
          }
        } else {
          return DateTime.now();
        }
      }
      
      return CallAlertModel(
        alertId: map['alertId'] ?? '',
        childId: map['childId'] ?? '',
        number: map['number'] ?? '',
        reason: map['reason'] ?? '',
        duration: map['duration'] ?? 0,
        timestamp: parseTimestamp(map['timestamp']),
        rule: map['rule'] ?? '',
        callType: map['callType'] ?? 'UNKNOWN',
        countLast24h: map['countLast24h'] ?? 0,
        createdAt: parseCreatedAt(map['createdAt']),
        contactName: map['contactName'],
        isFalsePositive: map['isFalsePositive'] ?? false, // Default false if missing
      );
    } catch (e, stackTrace) {
      print('❌ [CallAlertModel] Error in fromMap: $e');
      print('   Stack trace: $stackTrace');
      print('   Map data: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'childId': childId,
      'number': number,
      'reason': reason,
      'duration': duration,
      'timestamp': Timestamp.fromDate(timestamp), // Save as Firestore Timestamp for proper querying
      'rule': rule,
      'callType': callType,
      'countLast24h': countLast24h,
      'createdAt': FieldValue.serverTimestamp(),
      'contactName': contactName,
      'isFalsePositive': isFalsePositive,
    };
  }
}

