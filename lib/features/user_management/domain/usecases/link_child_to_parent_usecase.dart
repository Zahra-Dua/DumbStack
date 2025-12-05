import 'package:parental_control_app/features/user_management/domain/repositories/pairing_repository.dart';

class LinkChildToParentUseCase {
  final PairingRepository repository;
  LinkChildToParentUseCase(this.repository);

  Future<void> call({
    required String parentUid,
    required String firstName,
    required String lastName,
    required String childName,
    required int age,
    required String gender,
    required List<String> hobbies,
  }) {
    return repository.linkChildToParent(
      parentUid: parentUid,
      firstName: firstName,
      lastName: lastName,
      childName: childName,
      age: age,
      gender: gender,
      hobbies: hobbies,
    );
  }
}
