import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/report_repository.dart';

class RenameReportUseCase implements UseCase<void, RenameReportParams> {
  final ReportRepository repository;

  RenameReportUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RenameReportParams params) async {
    return await repository.renameReport(
      childId: params.childId,
      parentId: params.parentId,
      reportId: params.reportId,
      oldFileName: params.oldFileName,
      newFileName: params.newFileName,
      localPath: params.localPath,
    );
  }
}

class RenameReportParams extends Equatable {
  final String childId;
  final String parentId;
  final String reportId;
  final String oldFileName;
  final String newFileName;
  final String? localPath;

  const RenameReportParams({
    required this.childId,
    required this.parentId,
    required this.reportId,
    required this.oldFileName,
    required this.newFileName,
    required this.localPath,
  });

  @override
  List<Object> get props => [childId, parentId, reportId, oldFileName, newFileName, localPath ?? ''];
}

