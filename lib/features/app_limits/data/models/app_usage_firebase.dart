import 'package:cloud_firestore/cloud_firestore.dart';

class AppUsageFirebase {
  final String id;
  final String packageName;
  final String appName;
  final int usageDuration; // in minutes
  final int launchCount;
  final DateTime lastUsed;
  final String? appIcon;
  final Map<String, dynamic>? metadata;
  final bool isSystemApp;
  final double? riskScore;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUsageFirebase({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.usageDuration,
    required this.launchCount,
    required this.lastUsed,
    this.appIcon,
    this.metadata,
    this.isSystemApp = false,
    this.riskScore,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUsageFirebase.fromJson(Map<String, dynamic> json) {
    return AppUsageFirebase(
      id: json['id'] ?? '',
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      usageDuration: json['usageDuration'] ?? 0,
      launchCount: json['launchCount'] ?? 0,
      lastUsed: (json['lastUsed'] as Timestamp).toDate(),
      appIcon: json['appIcon'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
      isSystemApp: json['isSystemApp'] ?? false,
      riskScore: json['riskScore']?.toDouble(),
      isBlocked: json['isBlocked'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'usageDuration': usageDuration,
      'launchCount': launchCount,
      'lastUsed': Timestamp.fromDate(lastUsed),
      'appIcon': appIcon,
      'metadata': metadata,
      'isSystemApp': isSystemApp,
      'riskScore': riskScore,
      'isBlocked': isBlocked,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppUsageFirebase copyWith({
    String? id,
    String? packageName,
    String? appName,
    int? usageDuration,
    int? launchCount,
    DateTime? lastUsed,
    String? appIcon,
    Map<String, dynamic>? metadata,
    bool? isSystemApp,
    double? riskScore,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUsageFirebase(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      usageDuration: usageDuration ?? this.usageDuration,
      launchCount: launchCount ?? this.launchCount,
      lastUsed: lastUsed ?? this.lastUsed,
      appIcon: appIcon ?? this.appIcon,
      metadata: metadata ?? this.metadata,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      riskScore: riskScore ?? this.riskScore,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}