import 'package:firebase_auth/firebase_auth.dart';
import 'package:parental_control_app/features/user_management/data/datasources/user_remote_datasource.dart';
import 'package:parental_control_app/features/user_management/domain/repositories/user_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  AuthRepositoryImpl({required this.remote});

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
  }) {
    return remote.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      userType: userType,
    );
  }

  @override
  Future<User> signIn({required String email, required String password}) {
    return remote.signIn(email: email, password: password);
  }

  @override
  Future<User> signInAnonymously() {
    return remote.signInAnonymously();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return remote.sendPasswordResetEmail(email: email);
  }

  @override
  Future<String> verifyPasswordResetCode({required String code}) {
    return remote.verifyPasswordResetCode(code: code);
  }

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) {
    return remote.confirmPasswordReset(code: code, newPassword: newPassword);
  }
}
