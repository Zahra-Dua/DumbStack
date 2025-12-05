import 'package:cloud_firestore/cloud_firestore.dart';

class WatchListContactModel {
  final String id;
  final String parentId;
  final String childId;
  final String contactName;
  final String phoneNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WatchListContactModel({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.contactName,
    required this.phoneNumber,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'childId': childId,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory WatchListContactModel.fromMap(Map<String, dynamic> map) {
    return WatchListContactModel(
      id: map['id'] ?? '',
      parentId: map['parentId'] ?? '',
      childId: map['childId'] ?? '',
      contactName: map['contactName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory WatchListContactModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WatchListContactModel.fromMap({
      ...data,
      'id': doc.id,
    });
  }

  WatchListContactModel copyWith({
    String? id,
    String? parentId,
    String? childId,
    String? contactName,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WatchListContactModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

