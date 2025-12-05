import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String childId;
  final String parentId;
  final String fileName;
  final String reportType; // 'weekly', 'monthly', 'custom'
  final DateTime startDate;
  final DateTime endDate;
  final String? localPath; // Local file path instead of downloadUrl
  final DateTime generatedAt;
  final Map<String, dynamic>? summary; // Total screen time, top apps, etc.

  ReportModel({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.fileName,
    required this.reportType,
    required this.startDate,
    required this.endDate,
    this.localPath,
    required this.generatedAt,
    this.summary,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      parentId: json['parentId'] ?? '',
      fileName: json['fileName'] ?? '',
      reportType: json['reportType'] ?? 'weekly',
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      localPath: json['localPath'],
      generatedAt: (json['generatedAt'] as Timestamp).toDate(),
      summary: json['summary'] != null
          ? Map<String, dynamic>.from(json['summary'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'parentId': parentId,
      'fileName': fileName,
      'reportType': reportType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'localPath': localPath,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'summary': summary,
    };
  }

  ReportModel copyWith({
    String? id,
    String? childId,
    String? parentId,
    String? fileName,
    String? reportType,
    DateTime? startDate,
    DateTime? endDate,
    String? localPath,
    DateTime? generatedAt,
    Map<String, dynamic>? summary,
  }) {
    return ReportModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      fileName: fileName ?? this.fileName,
      reportType: reportType ?? this.reportType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      localPath: localPath ?? this.localPath,
      generatedAt: generatedAt ?? this.generatedAt,
      summary: summary ?? this.summary,
    );
  }
}

