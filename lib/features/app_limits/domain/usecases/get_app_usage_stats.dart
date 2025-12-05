import '../entities/app_usage_entity.dart';
import '../repositories/app_limits_repository.dart';

class GetAppUsageStats {
  final AppLimitsRepository repository;

  GetAppUsageStats(this.repository);

  Future<List<AppUsageEntity>> call() async {
    return await repository.getAppUsageStats();
  }
}
