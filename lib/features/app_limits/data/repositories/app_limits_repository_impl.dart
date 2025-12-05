import '../../domain/entities/app_usage_entity.dart';
import '../../domain/entities/app_limit_entity.dart';
import '../../domain/entities/global_limit_entity.dart';
import '../../domain/repositories/app_limits_repository.dart';
import '../datasources/usage_stats_service.dart';
import '../datasources/local_storage_service.dart';

class AppLimitsRepositoryImpl implements AppLimitsRepository {
  final UsageStatsService _usageStatsService;
  final LocalStorageService _localStorageService;

  AppLimitsRepositoryImpl(this._usageStatsService, this._localStorageService);

  @override
  Future<List<AppUsageEntity>> getAppUsageStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final stats = await _usageStatsService.getAppUsageStats(
      startTime: startOfDay,
      endTime: now,
    );
    final limits = await _localStorageService.getAppDailyLimits();
    
    return stats.map((stat) {
      final limit = limits[stat.packageName];
      return AppUsageEntity(
        packageName: stat.packageName,
        appName: stat.appName,
        iconPath: stat.iconPath,
        totalTimeInForeground: stat.totalTimeInForeground,
        lastTimeUsed: stat.lastTimeUsed,
        dailyLimitMinutes: limit?['dailyLimitMinutes'] ?? 0,
        usedMinutes: limit?['usedMinutes'] ?? 0,
        isRestricted: (limit?['isRestricted'] ?? false) && (limit?['usedMinutes'] ?? 0) >= (limit?['dailyLimitMinutes'] ?? 0),
      );
    }).toList();
  }

  @override
  Future<List<AppLimitEntity>> getAppLimits() async {
    final limits = await _localStorageService.getAppDailyLimits();
    return limits.entries.map((entry) => AppLimitEntity(
      packageName: entry.key,
      dailyLimitMinutes: entry.value['dailyLimitMinutes'] ?? 0,
      usedMinutes: entry.value['usedMinutes'] ?? 0,
      lastUpdated: DateTime.tryParse(entry.value['lastReset'] ?? '') ?? DateTime.now(),
      isActive: entry.value['isRestricted'] ?? false,
    )).toList();
  }

  @override
  Future<GlobalLimitEntity?> getGlobalLimit() async {
    final limit = await _localStorageService.getGlobalDailyLimit();
    if (limit == null) return null;
    
    return GlobalLimitEntity(
      dailyLimitMinutes: limit['dailyLimitMinutes'] ?? 0,
      usedMinutes: limit['usedMinutes'] ?? 0,
      lastUpdated: DateTime.tryParse(limit['lastReset'] ?? '') ?? DateTime.now(),
      isActive: limit['isRestricted'] ?? false,
    );
  }

  @override
  Future<void> setAppLimit(String packageName, int dailyLimitMinutes) async {
    await _localStorageService.setAppDailyLimit(packageName, dailyLimitMinutes);
  }

  @override
  Future<void> clearAppLimit(String packageName) async {
    await _localStorageService.clearAppDailyLimit(packageName);
    await _usageStatsService.clearAppRestriction(packageName);
  }

  @override
  Future<void> setGlobalLimit(int dailyLimitMinutes) async {
    await _localStorageService.setGlobalDailyLimit(dailyLimitMinutes);
  }

  @override
  Future<void> clearGlobalLimit() async {
    await _localStorageService.clearGlobalDailyLimit();
  }

  @override
  Future<void> setAppRestriction(String packageName, bool isRestricted) async {
    if (isRestricted) {
      // Set restriction until end of day
      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      await _usageStatsService.setAppRestriction(packageName, endOfDay);
    } else {
      // Clear restriction
      await _usageStatsService.clearAppRestriction(packageName);
    }
  }

  @override
  Future<void> clearAppRestriction(String packageName) async {
    await _usageStatsService.clearAppRestriction(packageName);
  }

  @override
  Future<void> clearAllRestrictions() async {
    await _usageStatsService.clearAllRestrictions();
  }

  @override
  Future<bool> isAppRestricted(String packageName) async {
    // This would need to be implemented in the service
    return false;
  }

  @override
  Future<void> requestLockNow() async {
    await _usageStatsService.requestLockNow();
  }

  @override
  Future<void> resetDailyIfNeeded() async {
    await _localStorageService.resetDailyIfNeeded();
  }
}
