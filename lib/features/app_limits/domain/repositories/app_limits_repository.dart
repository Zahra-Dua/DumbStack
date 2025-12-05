import '../entities/app_usage_entity.dart';
import '../entities/app_limit_entity.dart';
import '../entities/global_limit_entity.dart';

abstract class AppLimitsRepository {
  Future<List<AppUsageEntity>> getAppUsageStats();
  Future<List<AppLimitEntity>> getAppLimits();
  Future<GlobalLimitEntity?> getGlobalLimit();
  
  Future<void> setAppLimit(String packageName, int dailyLimitMinutes);
  Future<void> clearAppLimit(String packageName);
  Future<void> setGlobalLimit(int dailyLimitMinutes);
  Future<void> clearGlobalLimit();
  
  Future<void> setAppRestriction(String packageName, bool isRestricted);
  Future<void> clearAppRestriction(String packageName);
  Future<void> clearAllRestrictions();
  Future<bool> isAppRestricted(String packageName);
  
  Future<void> requestLockNow();
  Future<void> resetDailyIfNeeded();
}
