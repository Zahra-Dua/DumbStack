import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<User> signIn({required String email, required String password});
  Future<User> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String userType,
  });
  Future<User> signInAnonymously();
  Future<void> sendPasswordResetEmail({required String email});
  Future<String> verifyPasswordResetCode({required String code});
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  });
}
