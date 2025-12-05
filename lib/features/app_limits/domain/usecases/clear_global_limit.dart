import '../repositories/app_limits_repository.dart';

class ClearGlobalLimitUseCase {
  final AppLimitsRepository repository;

  ClearGlobalLimitUseCase(this.repository);

  Future<void> call() async {
    await repository.clearGlobalLimit();
  }
}
