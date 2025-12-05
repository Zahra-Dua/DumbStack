import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/usecases/fetch_report_data_usecase.dart';
import '../../domain/usecases/generate_report_usecase.dart';
import '../../domain/usecases/get_reports_usecase.dart';
import '../../domain/usecases/delete_report_usecase.dart';
import '../../domain/usecases/rename_report_usecase.dart';
import '../../data/services/pdf_generator_service.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final FetchReportDataUseCase fetchReportDataUseCase;
  final GenerateReportUseCase generateReportUseCase;
  final GetReportsUseCase getReportsUseCase;
  final DeleteReportUseCase deleteReportUseCase;
  final RenameReportUseCase renameReportUseCase;
  final PdfGeneratorService pdfGeneratorService;

  ReportBloc({
    required this.fetchReportDataUseCase,
    required this.generateReportUseCase,
    required this.getReportsUseCase,
    required this.deleteReportUseCase,
    required this.renameReportUseCase,
    required this.pdfGeneratorService,
  }) : super(const ReportInitial()) {
    on<FetchReportDataEvent>(_onFetchReportData);
    on<GenerateReportEvent>(_onGenerateReport);
    on<GetReportsEvent>(_onGetReports);
    on<DeleteReportEvent>(_onDeleteReport);
    on<RenameReportEvent>(_onRenameReport);
    on<ResetReportStateEvent>(_onResetState);
  }

  Future<void> _onFetchReportData(
    FetchReportDataEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());
    final result = await fetchReportDataUseCase(
      FetchReportDataParams(
        childId: event.childId,
        parentId: event.parentId,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (failure) => emit(ReportError(failure.message)),
      (reportData) => emit(ReportDataLoaded(reportData)),
    );
  }

  Future<void> _onGenerateReport(
    GenerateReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());

    // First fetch the data
    final fetchResult = await fetchReportDataUseCase(
      FetchReportDataParams(
        childId: event.childId,
        parentId: event.parentId,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    await fetchResult.fold(
      (failure) async {
        emit(ReportError(failure.message));
      },
      (reportData) async {
        // Generate PDF
        try {
          final pdfBytes = await pdfGeneratorService.generateReportPdf(
            childName: event.childName,
            reportType: event.reportType,
            startDate: event.startDate,
            endDate: event.endDate,
            reportData: reportData,
          );

          // Generate report ID
          const uuid = Uuid();
          final reportId = uuid.v4();

          // Save locally and save metadata
          final generateResult = await generateReportUseCase(
            GenerateReportParams(
              reportId: reportId,
              childId: event.childId,
              parentId: event.parentId,
              fileName: event.fileName,
              reportType: event.reportType,
              startDate: event.startDate,
              endDate: event.endDate,
              pdfBytes: pdfBytes.toList(),
              summary: {
                'totalScreenTime': reportData.totalScreenTime,
                'totalUrlsVisited': reportData.totalUrlsVisited,
                'totalAppsUsed': reportData.totalAppsUsed,
              },
            ),
          );

          generateResult.fold(
            (failure) => emit(ReportError(failure.message)),
            (localPath) => emit(ReportGenerated(localPath)),
          );
        } catch (e) {
          emit(ReportError('Error generating PDF: $e'));
        }
      },
    );
  }

  Future<void> _onGetReports(
    GetReportsEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());
    final result = await getReportsUseCase(
      GetReportsParams(
        childId: event.childId,
        parentId: event.parentId,
      ),
    );

    result.fold(
      (failure) => emit(ReportError(failure.message)),
      (reports) => emit(ReportsListLoaded(reports)),
    );
  }

  Future<void> _onDeleteReport(
    DeleteReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());
    final result = await deleteReportUseCase(
      DeleteReportParams(
        childId: event.childId,
        parentId: event.parentId,
        reportId: event.reportId,
        localPath: event.localPath,
      ),
    );

    result.fold(
      (failure) => emit(ReportError(failure.message)),
      (_) {
        emit(const ReportDeleted());
        // Reload reports list
        add(GetReportsEvent(
          childId: event.childId,
          parentId: event.parentId,
        ));
      },
    );
  }

  Future<void> _onRenameReport(
    RenameReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(const ReportLoading());
    final result = await renameReportUseCase(
      RenameReportParams(
        childId: event.childId,
        parentId: event.parentId,
        reportId: event.reportId,
        oldFileName: event.oldFileName,
        newFileName: event.newFileName,
        localPath: event.localPath,
      ),
    );

    result.fold(
      (failure) => emit(ReportError(failure.message)),
      (_) {
        emit(const ReportRenamed());
        // Reload reports list
        add(GetReportsEvent(
          childId: event.childId,
          parentId: event.parentId,
        ));
      },
    );
  }

  void _onResetState(
    ResetReportStateEvent event,
    Emitter<ReportState> emit,
  ) {
    emit(const ReportInitial());
  }
}
