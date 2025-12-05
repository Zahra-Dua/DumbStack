import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/parent_dashboard_event.dart';
import '../bloc/parent_dashboard_state.dart';
import '../../data/services/parent_dashboard_firebase_service.dart';
import '../../../url_tracking/data/models/visited_url_firebase.dart';
import '../../../app_limits/data/models/app_usage_firebase.dart';
import '../../../app_limits/data/models/installed_app_firebase.dart';

class ParentDashboardBloc extends Bloc<ParentDashboardEvent, ParentDashboardState> {
  final ParentDashboardFirebaseService _firebaseService;

  ParentDashboardBloc({required ParentDashboardFirebaseService firebaseService})
      : _firebaseService = firebaseService,
        super(ParentDashboardInitial()) {
    
    on<LoadDashboardData>(_onLoadDashboardData);
    on<UpdateUrlBlockStatus>(_onUpdateUrlBlockStatus);
    on<RefreshData>(_onRefreshData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<ParentDashboardState> emit,
  ) async {
    emit(ParentDashboardLoading());

    try {
      // Load all data in parallel
      final futures = await Future.wait([
        _firebaseService.getVisitedUrlsStream(
          childId: event.childId,
          parentId: event.parentId,
        ).first,
        _firebaseService.getAppUsageStream(
          childId: event.childId,
          parentId: event.parentId,
        ).first,
        _firebaseService.getInstalledAppsStream(
          childId: event.childId,
          parentId: event.parentId,
        ).first,
        _firebaseService.getTodayAppUsageSummary(
          childId: event.childId,
          parentId: event.parentId,
        ),
        _firebaseService.getWeekAppUsageSummary(
          childId: event.childId,
          parentId: event.parentId,
        ),
        _firebaseService.getDailyScreenTime(
          childId: event.childId,
          parentId: event.parentId,
        ),
        _firebaseService.getMostUsedApps(
          childId: event.childId,
          parentId: event.parentId,
          limit: 20,
        ),
      ]);

      final recentUrls = futures[0] as List<VisitedUrlFirebase>;
      final allApps = futures[1] as List<AppUsageFirebase>;
      final installedApps = futures[2] as List<InstalledAppFirebase>;
      final todaySummary = futures[3] as Map<String, dynamic>;
      final weekSummary = futures[4] as Map<String, dynamic>;
      final dailyScreenTime = futures[5] as List<Map<String, dynamic>>;
      final mostUsedApps = futures[6] as List<AppUsageFirebase>;

      emit(ParentDashboardLoaded(
        recentUrls: recentUrls,
        mostUsedApps: mostUsedApps,
        allApps: allApps,
        installedApps: installedApps,
        todaySummary: todaySummary,
        weekSummary: weekSummary,
        dailyScreenTime: dailyScreenTime,
      ));
    } catch (e) {
      emit(ParentDashboardError('Failed to load dashboard data: $e'));
    }
  }

  Future<void> _onUpdateUrlBlockStatus(
    UpdateUrlBlockStatus event,
    Emitter<ParentDashboardState> emit,
  ) async {
    try {
      await _firebaseService.updateUrlBlockStatus(
        childId: event.childId,
        parentId: event.parentId,
        urlId: event.urlId,
        isBlocked: event.isBlocked,
      );

      // Reload data to reflect changes
      add(LoadDashboardData(
        childId: event.childId,
        parentId: event.parentId,
      ));
    } catch (e) {
      emit(ParentDashboardError('Failed to update URL block status: $e'));
    }
  }

  Future<void> _onRefreshData(
    RefreshData event,
    Emitter<ParentDashboardState> emit,
  ) async {
    add(LoadDashboardData(
      childId: event.childId,
      parentId: event.parentId,
    ));
  }
}
