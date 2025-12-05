import '../repositories/app_limits_repository.dart';

class ClearAppLimitUseCase {
  final AppLimitsRepository repository;

  ClearAppLimitUseCase(this.repository);

  Future<void> call(String packageName) async {
    await repository.clearAppLimit(packageName);
  }
}
