import '../repositories/app_limits_repository.dart';

class SetAppLimitUseCase {
  final AppLimitsRepository repository;

  SetAppLimitUseCase(this.repository);

  Future<void> call(String packageName, int dailyLimitMinutes) async {
    await repository.setAppLimit(packageName, dailyLimitMinutes);
  }
}
