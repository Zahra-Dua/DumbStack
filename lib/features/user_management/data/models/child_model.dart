import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/qr_code_service.dart';

class ChildModel {
  final String childId;
  final String parentId;
  final String name;
  final String email;
  final String userType;
  final String avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? deviceInfo;
  final bool isActive;
  final List<String>? restrictions;
  
  // Profile fields
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? gender;
  final List<String>? hobbies;
  
  // Location tracking fields
  final double? currentLatitude;
  final double? currentLongitude;
  final String? currentAddress;
  final double? locationAccuracy;
  final DateTime? lastLocationUpdate;
  final bool isLocationTrackingEnabled;
  final List<Map<String, dynamic>>? locationHistory; // Recent location history
  final String? currentLocationStatus; // 'online', 'offline', 'unknown'

  ChildModel({
    required this.childId,
    required this.parentId,
    required this.name,
    required this.email,
    this.userType = 'child',
    this.avatarUrl = '',
    required this.createdAt,
    required this.updatedAt,
    this.deviceInfo,
    this.isActive = true,
    this.restrictions,
    this.firstName,
    this.lastName,
    this.age,
    this.gender,
    this.hobbies,
    this.currentLatitude,
    this.currentLongitude,
    this.currentAddress,
    this.locationAccuracy,
    this.lastLocationUpdate,
    this.isLocationTrackingEnabled = true,
    this.locationHistory,
    this.currentLocationStatus = 'unknown',
  });

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'parentId': parentId,
      'name': name,
      'email': email,
      'userType': userType,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deviceInfo': deviceInfo,
      'isActive': isActive,
      'restrictions': restrictions,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'gender': gender,
      'hobbies': hobbies,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'currentAddress': currentAddress,
      'locationAccuracy': locationAccuracy,
      'lastLocationUpdate': lastLocationUpdate,
      'isLocationTrackingEnabled': isLocationTrackingEnabled,
      'locationHistory': locationHistory,
      'currentLocationStatus': currentLocationStatus,
    };
  }

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      childId: map['childId'] ?? '',
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      userType: map['userType'] ?? 'child',
      avatarUrl: map['avatarUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deviceInfo: map['deviceInfo'],
      isActive: map['isActive'] ?? true,
      restrictions: map['restrictions'] != null 
          ? List<String>.from(map['restrictions']) 
          : null,
      firstName: map['firstName'] as String?,
      lastName: map['lastName'] as String?,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      hobbies: map['hobbies'] != null 
          ? List<String>.from(map['hobbies']) 
          : null,
      currentLatitude: map['currentLatitude']?.toDouble(),
      currentLongitude: map['currentLongitude']?.toDouble(),
      currentAddress: map['currentAddress'],
      locationAccuracy: map['locationAccuracy']?.toDouble(),
      lastLocationUpdate: (map['lastLocationUpdate'] as Timestamp?)?.toDate(),
      isLocationTrackingEnabled: map['isLocationTrackingEnabled'] ?? true,
      locationHistory: map['locationHistory'] != null 
          ? List<Map<String, dynamic>>.from(map['locationHistory']) 
          : null,
      currentLocationStatus: map['currentLocationStatus'] ?? 'unknown',
    );
  }

  /// Generate QR code data for this child profile
  Map<String, dynamic> generateQRData() {
    return QRCodeService.generateUserProfileQRData(
      uid: childId,
      name: name,
      email: email,
      userType: userType,
    );
  }

  /// Generate QR code JSON string for this child
  String generateQRString() {
    return QRCodeService.dataToJson(generateQRData());
  }

  /// Generate device pairing QR data
  Map<String, dynamic> generateDevicePairingQRData(String deviceName) {
    return QRCodeService.generateDevicePairingQRData(
      deviceId: childId,
      deviceName: deviceName,
      ownerUid: parentId,
    );
  }

  /// Check if child can generate family invites (always false for children)
  bool canGenerateFamilyInvites() {
    return false;
  }

  /// Get user type for display
  String get displayUserType {
    return 'Child';
  }

  /// Check if child has current location
  bool get hasCurrentLocation {
    return currentLatitude != null && currentLongitude != null;
  }

  /// Get location status color
  String get locationStatusColor {
    switch (currentLocationStatus) {
      case 'online':
        return 'green';
      case 'offline':
        return 'red';
      case 'unknown':
        return 'orange';
      default:
        return 'grey';
    }
  }

  /// Get formatted last location update time
  String get lastLocationUpdateText {
    if (lastLocationUpdate == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastLocationUpdate!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get location accuracy description
  String get locationAccuracyText {
    if (locationAccuracy == null) return 'Unknown';
    if (locationAccuracy! < 10) return 'High';
    if (locationAccuracy! < 50) return 'Medium';
    return 'Low';
  }

  /// Update location with new coordinates
  ChildModel updateLocation({
    required double latitude,
    required double longitude,
    String? address,
    double? accuracy,
  }) {
    final now = DateTime.now();
    final newLocationEntry = {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'timestamp': now.toIso8601String(),
    };

    // Add to location history (keep last 50 entries)
    final updatedHistory = List<Map<String, dynamic>>.from(locationHistory ?? []);
    updatedHistory.insert(0, newLocationEntry);
    if (updatedHistory.length > 50) {
      updatedHistory.removeRange(50, updatedHistory.length);
    }

    return copyWith(
      currentLatitude: latitude,
      currentLongitude: longitude,
      currentAddress: address,
      locationAccuracy: accuracy,
      lastLocationUpdate: now,
      locationHistory: updatedHistory,
      currentLocationStatus: 'online',
      updatedAt: now,
    );
  }

  /// Update location status
  ChildModel updateLocationStatus(String status) {
    return copyWith(
      currentLocationStatus: status,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle location tracking
  ChildModel toggleLocationTracking() {
    return copyWith(
      isLocationTrackingEnabled: !isLocationTrackingEnabled,
      updatedAt: DateTime.now(),
    );
  }

  /// Update child information
  ChildModel copyWith({
    String? childId,
    String? parentId,
    String? name,
    String? email,
    String? userType,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? deviceInfo,
    bool? isActive,
    List<String>? restrictions,
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    List<String>? hobbies,
    double? currentLatitude,
    double? currentLongitude,
    String? currentAddress,
    double? locationAccuracy,
    DateTime? lastLocationUpdate,
    bool? isLocationTrackingEnabled,
    List<Map<String, dynamic>>? locationHistory,
    String? currentLocationStatus,
  }) {
    return ChildModel(
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isActive: isActive ?? this.isActive,
      restrictions: restrictions ?? this.restrictions,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      hobbies: hobbies ?? this.hobbies,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentAddress: currentAddress ?? this.currentAddress,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      isLocationTrackingEnabled: isLocationTrackingEnabled ?? this.isLocationTrackingEnabled,
      locationHistory: locationHistory ?? this.locationHistory,
      currentLocationStatus: currentLocationStatus ?? this.currentLocationStatus,
    );
  }
}
