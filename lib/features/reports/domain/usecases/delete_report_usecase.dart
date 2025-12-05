import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/report_repository.dart';

class DeleteReportUseCase implements UseCase<void, DeleteReportParams> {
  final ReportRepository repository;

  DeleteReportUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteReportParams params) async {
    return await repository.deleteReport(
      childId: params.childId,
      parentId: params.parentId,
      reportId: params.reportId,
      localPath: params.localPath,
    );
  }
}

class DeleteReportParams extends Equatable {
  final String childId;
  final String parentId;
  final String reportId;
  final String? localPath;

  const DeleteReportParams({
    required this.childId,
    required this.parentId,
    required this.reportId,
    required this.localPath,
  });

  @override
  List<Object?> get props => [childId, parentId, reportId, localPath];
}
