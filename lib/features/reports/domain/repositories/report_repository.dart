import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/report_entity.dart';
import '../entities/report_data_entity.dart';

abstract class ReportRepository {
  Future<Either<Failure, ReportDataEntity>> fetchReportData({
    required String childId,
    required String parentId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, String>> saveReportLocally({
    required String fileName,
    required List<int> pdfBytes,
  });

  Future<Either<Failure, void>> saveReportMetadata({
    required ReportEntity report,
  });

  Future<Either<Failure, List<ReportEntity>>> getReports({
    required String childId,
    required String parentId,
  });

  Future<Either<Failure, void>> deleteReport({
    required String childId,
    required String parentId,
    required String reportId,
    required String? localPath,
  });

  Future<Either<Failure, void>> renameReport({
    required String childId,
    required String parentId,
    required String reportId,
    required String oldFileName,
    required String newFileName,
    required String? localPath,
  });

  Future<Either<Failure, File?>> getReportFile(String localPath);
}
