import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class FetchReportDataEvent extends ReportEvent {
  final String childId;
  final String parentId;
  final DateTime startDate;
  final DateTime endDate;

  const FetchReportDataEvent({
    required this.childId,
    required this.parentId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [childId, parentId, startDate, endDate];
}

class GenerateReportEvent extends ReportEvent {
  final String childId;
  final String parentId;
  final String childName;
  final String fileName;
  final String reportType;
  final DateTime startDate;
  final DateTime endDate;

  const GenerateReportEvent({
    required this.childId,
    required this.parentId,
    required this.childName,
    required this.fileName,
    required this.reportType,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [
        childId,
        parentId,
        childName,
        fileName,
        reportType,
        startDate,
        endDate,
      ];
}

class GetReportsEvent extends ReportEvent {
  final String childId;
  final String parentId;

  const GetReportsEvent({
    required this.childId,
    required this.parentId,
  });

  @override
  List<Object> get props => [childId, parentId];
}

class DeleteReportEvent extends ReportEvent {
  final String childId;
  final String parentId;
  final String reportId;
  final String? localPath;

  const DeleteReportEvent({
    required this.childId,
    required this.parentId,
    required this.reportId,
    required this.localPath,
  });

  @override
  List<Object?> get props => [childId, parentId, reportId, localPath];
}

class RenameReportEvent extends ReportEvent {
  final String childId;
  final String parentId;
  final String reportId;
  final String oldFileName;
  final String newFileName;
  final String? localPath;

  const RenameReportEvent({
    required this.childId,
    required this.parentId,
    required this.reportId,
    required this.oldFileName,
    required this.newFileName,
    required this.localPath,
  });

  @override
  List<Object?> get props => [childId, parentId, reportId, oldFileName, newFileName, localPath];
}

class OpenReportEvent extends ReportEvent {
  final String localPath;

  const OpenReportEvent({required this.localPath});

  @override
  List<Object> get props => [localPath];
}

class ResetReportStateEvent extends ReportEvent {
  const ResetReportStateEvent();
}
