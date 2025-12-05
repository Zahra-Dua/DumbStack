import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GenerateReportUseCase implements UseCase<String, GenerateReportParams> {
  final ReportRepository repository;

  GenerateReportUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(GenerateReportParams params) async {
    // First save PDF locally
    final saveResult = await repository.saveReportLocally(
      fileName: params.fileName,
      pdfBytes: params.pdfBytes,
    );

    return saveResult.fold(
      (failure) => Left(failure),
      (localPath) async {
        // Then save metadata in Firestore
        final report = ReportEntity(
          id: params.reportId,
          childId: params.childId,
          parentId: params.parentId,
          fileName: params.fileName,
          reportType: params.reportType,
          startDate: params.startDate,
          endDate: params.endDate,
          localPath: localPath,
          generatedAt: DateTime.now(),
          summary: params.summary,
        );

        final saveMetadataResult = await repository.saveReportMetadata(report: report);

        return saveMetadataResult.fold(
          (failure) => Left(failure),
          (_) => Right(localPath),
        );
      },
    );
  }
}

class GenerateReportParams extends Equatable {
  final String reportId;
  final String childId;
  final String parentId;
  final String fileName;
  final String reportType;
  final DateTime startDate;
  final DateTime endDate;
  final List<int> pdfBytes;
  final Map<String, dynamic>? summary;

  const GenerateReportParams({
    required this.reportId,
    required this.childId,
    required this.parentId,
    required this.fileName,
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.pdfBytes,
    this.summary,
  });

  @override
  List<Object?> get props => [
        reportId,
        childId,
        parentId,
        fileName,
        reportType,
        startDate,
        endDate,
        pdfBytes,
        summary,
      ];
}
