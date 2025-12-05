import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/entities/report_data_entity.dart';
import '../datasources/report_remote_datasource.dart';
import '../models/report_model.dart';
import '../models/report_data_model.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ReportDataEntity>> fetchReportData({
    required String childId,
    required String parentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final reportData = await remoteDataSource.fetchReportData(
        childId: childId,
        parentId: parentId,
        startDate: startDate,
        endDate: endDate,
      );

      return Right(_mapReportDataToEntity(reportData));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> saveReportLocally({
    required String fileName,
    required List<int> pdfBytes,
  }) async {
    try {
      final localPath = await remoteDataSource.saveReportLocally(
        fileName: fileName,
        pdfBytes: pdfBytes,
      );

      return Right(localPath);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveReportMetadata({
    required ReportEntity report,
  }) async {
    try {
      await remoteDataSource.saveReportMetadata(
        report: _mapToModel(report),
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReportEntity>>> getReports({
    required String childId,
    required String parentId,
  }) async {
    try {
      final reports = await remoteDataSource.getReports(
        childId: childId,
        parentId: parentId,
      );

      return Right(reports.map((model) => _mapReportToEntity(model)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReport({
    required String childId,
    required String parentId,
    required String reportId,
    required String? localPath,
  }) async {
    try {
      await remoteDataSource.deleteReport(
        childId: childId,
        parentId: parentId,
        reportId: reportId,
        localPath: localPath,
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> renameReport({
    required String childId,
    required String parentId,
    required String reportId,
    required String oldFileName,
    required String newFileName,
    required String? localPath,
  }) async {
    try {
      await remoteDataSource.renameReport(
        childId: childId,
        parentId: parentId,
        reportId: reportId,
        oldFileName: oldFileName,
        newFileName: newFileName,
        localPath: localPath,
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, File?>> getReportFile(String localPath) async {
    try {
      final file = await remoteDataSource.getReportFile(localPath);
      return Right(file);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  ReportDataEntity _mapReportDataToEntity(ReportDataModel model) {
    return model.toEntity();
  }

  ReportEntity _mapReportToEntity(ReportModel model) {
    return ReportEntity(
      id: model.id,
      childId: model.childId,
      parentId: model.parentId,
      fileName: model.fileName,
      reportType: model.reportType,
      startDate: model.startDate,
      endDate: model.endDate,
      localPath: model.localPath,
      generatedAt: model.generatedAt,
      summary: model.summary,
    );
  }

  ReportModel _mapToModel(ReportEntity entity) {
    return ReportModel(
      id: entity.id,
      childId: entity.childId,
      parentId: entity.parentId,
      fileName: entity.fileName,
      reportType: entity.reportType,
      startDate: entity.startDate,
      endDate: entity.endDate,
      localPath: entity.localPath,
      generatedAt: entity.generatedAt,
      summary: entity.summary,
    );
  }
}
