import '../repositories/app_limits_repository.dart';

class SetGlobalLimitUseCase {
  final AppLimitsRepository repository;

  SetGlobalLimitUseCase(this.repository);

  Future<void> call(int dailyLimitMinutes) async {
    await repository.setGlobalLimit(dailyLimitMinutes);
  }
}
