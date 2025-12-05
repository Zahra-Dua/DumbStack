import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final double accuracy;
  final DateTime timestamp;
  final bool isTrackingEnabled;
  final String status; // 'online', 'offline', 'unknown'

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.accuracy,
    required this.timestamp,
    required this.isTrackingEnabled,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'timestamp': Timestamp.fromDate(timestamp),
      'isTrackingEnabled': isTrackingEnabled,
      'status': status,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isTrackingEnabled: map['isTrackingEnabled'] ?? false,
      status: map['status'] ?? 'unknown',
    );
  }

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    double? accuracy,
    DateTime? timestamp,
    bool? isTrackingEnabled,
    String? status,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      isTrackingEnabled: isTrackingEnabled ?? this.isTrackingEnabled,
      status: status ?? this.status,
    );
  }
}
