import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GetReportsUseCase implements UseCase<List<ReportEntity>, GetReportsParams> {
  final ReportRepository repository;

  GetReportsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ReportEntity>>> call(GetReportsParams params) async {
    return await repository.getReports(
      childId: params.childId,
      parentId: params.parentId,
    );
  }
}

class GetReportsParams extends Equatable {
  final String childId;
  final String parentId;

  const GetReportsParams({
    required this.childId,
    required this.parentId,
  });

  @override
  List<Object> get props => [childId, parentId];
}

