import '../../domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/qr_code_service.dart';

class ParentModel extends UserEntity {
  final List<String> childIds;

  const ParentModel({
    required String parentId,
    required super.name,
    required super.email,
    required super.userType,
    required super.createdAt,
    required super.updatedAt,
    this.childIds = const [],
  }) : super(
          uid: parentId,
        );

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'userType': userType,
      'childIds': childIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      parentId: map['uid'] ?? map['parentId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      userType: map['userType'] ?? 'parent',
      childIds: List<String>.from(map['childIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Getter for parentId (same as uid)
  String get parentId => uid;

  /// Generate QR code data for this parent profile
  Map<String, dynamic> generateQRData() {
    return QRCodeService.generateUserProfileQRData(
      uid: parentId,
      name: name,
      email: email,
      userType: userType,
    );
  }

  /// Generate QR code JSON string for this parent
  String generateQRString() {
    return QRCodeService.dataToJson(generateQRData());
  }

  /// Generate family invite QR data
  Map<String, dynamic> generateFamilyInviteQRData() {
    return QRCodeService.generateFamilyInviteQRData(
      familyId: parentId, // Using parentId as familyId
      inviterName: name,
      inviterEmail: email,
    );
  }

  /// Add a child ID to the parent's childIds list
  ParentModel addChild(String childId) {
    if (!childIds.contains(childId)) {
      final updatedChildIds = List<String>.from(childIds)..add(childId);
      return ParentModel(
        parentId: parentId,
        name: name,
        email: email,
        userType: userType,
        childIds: updatedChildIds,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Remove a child ID from the parent's childIds list
  ParentModel removeChild(String childId) {
    final updatedChildIds = List<String>.from(childIds)..remove(childId);
    return ParentModel(
      parentId: parentId,
      name: name,
      email: email,
      userType: userType,
      childIds: updatedChildIds,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if parent can generate family invites (always true for parents)
  bool canGenerateFamilyInvites() {
    return true;
  }

  /// Get user type for display
  String get displayUserType {
    return 'Parent';
  }
}
