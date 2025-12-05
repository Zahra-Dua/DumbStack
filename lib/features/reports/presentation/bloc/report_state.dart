import 'package:equatable/equatable.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/entities/report_data_entity.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportDataLoaded extends ReportState {
  final ReportDataEntity reportData;

  const ReportDataLoaded(this.reportData);

  @override
  List<Object> get props => [reportData];
}

class ReportGenerated extends ReportState {
  final String localPath;

  const ReportGenerated(this.localPath);

  @override
  List<Object> get props => [localPath];
}

class ReportsListLoaded extends ReportState {
  final List<ReportEntity> reports;

  const ReportsListLoaded(this.reports);

  @override
  List<Object> get props => [reports];
}

class ReportDeleted extends ReportState {
  const ReportDeleted();
}

class ReportRenamed extends ReportState {
  const ReportRenamed();
}

class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object> get props => [message];
}
