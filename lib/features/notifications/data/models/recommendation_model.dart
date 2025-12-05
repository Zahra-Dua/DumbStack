import 'package:cloud_firestore/cloud_firestore.dart';

/// Recommendation Model
/// 
/// Represents AI-generated content recommendations for children
class RecommendationModel {
  final String id;
  final String parentId;
  final String childId;
  final String childName;
  final String recommendation;
  final DateTime timestamp;
  final RecommendationStatus status; // pending, approved, rejected
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final Map<String, dynamic>? childActivityData; // Data used to generate recommendation

  RecommendationModel({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.recommendation,
    required this.timestamp,
    this.status = RecommendationStatus.pending,
    this.approvedAt,
    this.rejectedAt,
    this.childActivityData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'childId': childId,
      'childName': childName,
      'recommendation': recommendation,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.value,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'childActivityData': childActivityData,
    };
  }

  factory RecommendationModel.fromMap(Map<String, dynamic> map) {
    return RecommendationModel(
      id: map['id'] ?? '',
      parentId: map['parentId'] ?? '',
      childId: map['childId'] ?? '',
      childName: map['childName'] ?? '',
      recommendation: map['recommendation'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: RecommendationStatusExtension.fromString(map['status'] ?? 'pending'),
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (map['rejectedAt'] as Timestamp?)?.toDate(),
      childActivityData: map['childActivityData'] as Map<String, dynamic>?,
    );
  }

  factory RecommendationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecommendationModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  RecommendationModel copyWith({
    String? id,
    String? parentId,
    String? childId,
    String? childName,
    String? recommendation,
    DateTime? timestamp,
    RecommendationStatus? status,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    Map<String, dynamic>? childActivityData,
  }) {
    return RecommendationModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      recommendation: recommendation ?? this.recommendation,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      childActivityData: childActivityData ?? this.childActivityData,
    );
  }
}

/// Recommendation Status Enum
enum RecommendationStatus {
  pending,
  approved,
  rejected;

  String get value {
    switch (this) {
      case RecommendationStatus.pending:
        return 'pending';
      case RecommendationStatus.approved:
        return 'approved';
      case RecommendationStatus.rejected:
        return 'rejected';
    }
  }
}

extension RecommendationStatusExtension on RecommendationStatus {
  static RecommendationStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return RecommendationStatus.approved;
      case 'rejected':
        return RecommendationStatus.rejected;
      default:
        return RecommendationStatus.pending;
    }
  }
}

