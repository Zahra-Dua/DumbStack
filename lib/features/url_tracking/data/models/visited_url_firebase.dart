import 'package:cloud_firestore/cloud_firestore.dart';

class VisitedUrlFirebase {
  final String id;
  final String url;
  final String title;
  final String packageName;
  final String? browserName;
  final DateTime visitedAt;
  final Map<String, dynamic>? metadata;
  final bool isBlocked;
  final bool isMalicious; // Flag for malicious URLs
  final bool isSpam; // Flag for spam URLs
  final String? threatType; // Type of threat (MALWARE, SOCIAL_ENGINEERING, etc.)
  final String? riskLevel; // Risk level (HIGH, MEDIUM, LOW)
  final DateTime createdAt;
  final DateTime updatedAt;

  VisitedUrlFirebase({
    required this.id,
    required this.url,
    required this.title,
    required this.packageName,
    this.browserName,
    required this.visitedAt,
    this.metadata,
    this.isBlocked = false,
    this.isMalicious = false,
    this.isSpam = false,
    this.threatType,
    this.riskLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisitedUrlFirebase.fromJson(Map<String, dynamic> json) {
    return VisitedUrlFirebase(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      title: json['title'] ?? '',
      packageName: json['packageName'] ?? '',
      browserName: json['browserName'],
      visitedAt: (json['visitedAt'] as Timestamp).toDate(),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
      isBlocked: json['isBlocked'] ?? false,
      isMalicious: json['isMalicious'] ?? false,
      isSpam: json['isSpam'] ?? false,
      threatType: json['threatType'],
      riskLevel: json['riskLevel'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'packageName': packageName,
      'browserName': browserName,
      'visitedAt': Timestamp.fromDate(visitedAt),
      'metadata': metadata,
      'isBlocked': isBlocked,
      'isMalicious': isMalicious,
      'isSpam': isSpam,
      'threatType': threatType,
      'riskLevel': riskLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  VisitedUrlFirebase copyWith({
    String? id,
    String? url,
    String? title,
    String? packageName,
    String? browserName,
    DateTime? visitedAt,
    Map<String, dynamic>? metadata,
    bool? isBlocked,
    bool? isMalicious,
    bool? isSpam,
    String? threatType,
    String? riskLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitedUrlFirebase(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      packageName: packageName ?? this.packageName,
      browserName: browserName ?? this.browserName,
      visitedAt: visitedAt ?? this.visitedAt,
      metadata: metadata ?? this.metadata,
      isBlocked: isBlocked ?? this.isBlocked,
      isMalicious: isMalicious ?? this.isMalicious,
      isSpam: isSpam ?? this.isSpam,
      threatType: threatType ?? this.threatType,
      riskLevel: riskLevel ?? this.riskLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}