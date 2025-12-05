import 'package:parental_control_app/features/user_management/domain/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInUseCase {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  Future<User> call({
    required String email,
    required String password,
  }) {
    return repository.signIn(email: email, password: password);
  }
}
