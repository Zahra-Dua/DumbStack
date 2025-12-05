import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  final String id;
  final String childId;
  final String parentId;
  final String fileName;
  final String reportType; // 'weekly', 'monthly', 'custom'
  final DateTime startDate;
  final DateTime endDate;
  final String? localPath;
  final DateTime generatedAt;
  final Map<String, dynamic>? summary;

  const ReportEntity({
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

  @override
  List<Object?> get props => [
        id,
        childId,
        parentId,
        fileName,
        reportType,
        startDate,
        endDate,
        localPath,
        generatedAt,
        summary,
      ];
}

