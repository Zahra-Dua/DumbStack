import '../../domain/entities/app_usage_entity.dart';

abstract class AppLimitsEvent {}

class LoadAppUsageStats extends AppLimitsEvent {}

class SetAppLimit extends AppLimitsEvent {
  final String packageName;
  final int dailyLimitMinutes;

  SetAppLimit(this.packageName, this.dailyLimitMinutes);
}

class ClearAppLimit extends AppLimitsEvent {
  final String packageName;

  ClearAppLimit(this.packageName);
}

class SetGlobalLimit extends AppLimitsEvent {
  final int dailyLimitMinutes;

  SetGlobalLimit(this.dailyLimitMinutes);
}

class ClearGlobalLimit extends AppLimitsEvent {}

class UpdateAppUsage extends AppLimitsEvent {
  final AppUsageEntity appUsage;

  UpdateAppUsage(this.appUsage);
}

class ResetDailyLimits extends AppLimitsEvent {}
