import '../../../url_tracking/data/models/visited_url_firebase.dart';
import '../../../app_limits/data/models/app_usage_firebase.dart';
import '../../../app_limits/data/models/installed_app_firebase.dart';

abstract class ParentDashboardState {}

class ParentDashboardInitial extends ParentDashboardState {}

class ParentDashboardLoading extends ParentDashboardState {}

class ParentDashboardLoaded extends ParentDashboardState {
  final List<VisitedUrlFirebase> recentUrls;
  final List<AppUsageFirebase> mostUsedApps;
  final List<AppUsageFirebase> allApps;
  final List<InstalledAppFirebase> installedApps;
  final Map<String, dynamic> todaySummary;
  final Map<String, dynamic> weekSummary;
  final List<Map<String, dynamic>> dailyScreenTime;

  ParentDashboardLoaded({
    required this.recentUrls,
    required this.mostUsedApps,
    required this.allApps,
    required this.installedApps,
    required this.todaySummary,
    required this.weekSummary,
    required this.dailyScreenTime,
  });
}

class ParentDashboardError extends ParentDashboardState {
  final String message;

  ParentDashboardError(this.message);
}
