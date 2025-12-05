import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/report_data_entity.dart';
import '../repositories/report_repository.dart';

class FetchReportDataUseCase implements UseCase<ReportDataEntity, FetchReportDataParams> {
  final ReportRepository repository;

  FetchReportDataUseCase(this.repository);

  @override
  Future<Either<Failure, ReportDataEntity>> call(FetchReportDataParams params) async {
    return await repository.fetchReportData(
      childId: params.childId,
      parentId: params.parentId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class FetchReportDataParams extends Equatable {
  final String childId;
  final String parentId;
  final DateTime startDate;
  final DateTime endDate;

  const FetchReportDataParams({
    required this.childId,
    required this.parentId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [childId, parentId, startDate, endDate];
}

