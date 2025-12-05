import 'package:cloud_firestore/cloud_firestore.dart';

class InstalledAppFirebase {
  final String id;
  final String packageName;
  final String appName;
  final String? iconPath;
  final String? versionName;
  final int? versionCode;
  final bool isSystemApp;
  final DateTime installTime;
  final DateTime lastUpdateTime;
  final DateTime detectedAt; // When this app was first detected by our system
  final bool isNewInstallation; // Flag for newly installed apps
  final DateTime createdAt;
  final DateTime updatedAt;

  InstalledAppFirebase({
    required this.id,
    required this.packageName,
    required this.appName,
    this.iconPath,
    this.versionName,
    this.versionCode,
    required this.isSystemApp,
    required this.installTime,
    required this.lastUpdateTime,
    required this.detectedAt,
    this.isNewInstallation = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstalledAppFirebase.fromJson(Map<String, dynamic> json) {
    return InstalledAppFirebase(
      id: json['id'] ?? '',
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      iconPath: json['iconPath'],
      versionName: json['versionName'],
      versionCode: json['versionCode'],
      isSystemApp: json['isSystemApp'] ?? false,
      installTime: (json['installTime'] as Timestamp).toDate(),
      lastUpdateTime: (json['lastUpdateTime'] as Timestamp).toDate(),
      detectedAt: (json['detectedAt'] as Timestamp).toDate(),
      isNewInstallation: json['isNewInstallation'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'iconPath': iconPath,
      'versionName': versionName,
      'versionCode': versionCode,
      'isSystemApp': isSystemApp,
      'installTime': Timestamp.fromDate(installTime),
      'lastUpdateTime': Timestamp.fromDate(lastUpdateTime),
      'detectedAt': Timestamp.fromDate(detectedAt),
      'isNewInstallation': isNewInstallation,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  InstalledAppFirebase copyWith({
    String? id,
    String? packageName,
    String? appName,
    String? iconPath,
    String? versionName,
    int? versionCode,
    bool? isSystemApp,
    DateTime? installTime,
    DateTime? lastUpdateTime,
    DateTime? detectedAt,
    bool? isNewInstallation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstalledAppFirebase(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconPath: iconPath ?? this.iconPath,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      installTime: installTime ?? this.installTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      detectedAt: detectedAt ?? this.detectedAt,
      isNewInstallation: isNewInstallation ?? this.isNewInstallation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

