import '../../domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/qr_code_service.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.userType,
    required super.createdAt,
    required super.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'userType': userType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      userType: map['userType'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Generate QR code data for this user profile
  Map<String, dynamic> generateQRData() {
    return QRCodeService.generateUserProfileQRData(
      uid: uid,
      name: name,
      email: email,
      userType: userType,
    );
  }

  /// Generate QR code JSON string for this user
  String generateQRString() {
    return QRCodeService.dataToJson(generateQRData());
  }

  /// Generate family invite QR data (if this user is a parent)
  Map<String, dynamic>? generateFamilyInviteQRData(String familyId) {
    // Debug information
    print('User type: "$userType"');
    print('User type lowercase: "${userType.toLowerCase()}"');
    print('Is parent: ${userType.toLowerCase() == 'parent'}');
    
    if (userType.toLowerCase() != 'parent') {
      print('Cannot generate family invite: User is not a parent');
      return null; // Only parents can generate family invites
    }
    
    return QRCodeService.generateFamilyInviteQRData(
      familyId: familyId,
      inviterName: name,
      inviterEmail: email,
    );
  }

  /// Check if user can generate family invites
  bool canGenerateFamilyInvites() {
    return userType.toLowerCase() == 'parent';
  }

  /// Get user type for display
  String get displayUserType {
    switch (userType.toLowerCase()) {
      case 'parent':
        return 'Parent';
      case 'child':
        return 'Child';
      case 'guardian':
        return 'Guardian';
      default:
        return userType;
    }
  }
}
