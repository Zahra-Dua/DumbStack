import 'package:parental_control_app/features/user_management/domain/repositories/user_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<void> sendResetEmail({required String email}) {
    return repository.sendPasswordResetEmail(email: email);
  }

  Future<String> verifyCode({required String code}) {
    return repository.verifyPasswordResetCode(code: code);
  }

  Future<String> verifyResetCode({required String code}) {
    return repository.verifyPasswordResetCode(code: code);
  }

  Future<void> confirmReset({
    required String code,
    required String newPassword,
  }) {
    return repository.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );
  }
}
