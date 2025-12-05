import '../../domain/entities/app_usage_entity.dart';
import '../../domain/entities/global_limit_entity.dart';

abstract class AppLimitsState {}

class AppLimitsInitial extends AppLimitsState {}

class AppLimitsLoading extends AppLimitsState {}

class AppLimitsLoaded extends AppLimitsState {
  final List<AppUsageEntity> appUsageStats;
  final GlobalLimitEntity? globalLimit;
  final String searchQuery;

  AppLimitsLoaded({
    required this.appUsageStats,
    this.globalLimit,
    this.searchQuery = '',
  });

  AppLimitsLoaded copyWith({
    List<AppUsageEntity>? appUsageStats,
    GlobalLimitEntity? globalLimit,
    String? searchQuery,
  }) {
    return AppLimitsLoaded(
      appUsageStats: appUsageStats ?? this.appUsageStats,
      globalLimit: globalLimit ?? this.globalLimit,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class AppLimitsError extends AppLimitsState {
  final String message;

  AppLimitsError(this.message);
}
