import 'package:parental_control_app/features/user_management/domain/repositories/pairing_repository.dart';
import 'package:parental_control_app/features/user_management/data/datasources/pairing_remote_datasource.dart';

class PairingRepositoryImpl implements PairingRepository {
  final PairingRemoteDataSource remote;
  PairingRepositoryImpl({required this.remote});

  @override
  Future<String> generateParentQRCode({required String parentUid}) {
    return remote.generateParentQRCode(parentUid: parentUid);
  }

  @override
  Future<void> linkChildToParent({
    required String parentUid,
    required String firstName,
    required String lastName,
    required String childName,
    required int age,
    required String gender,
    required List<String> hobbies,
  }) {
    return remote.linkChildToParent(
      parentUid: parentUid,
      firstName: firstName,
      lastName: lastName,
      childName: childName,
      age: age,
      gender: gender,
      hobbies: hobbies,
    );
  }

  @override
  Future<bool> isChildAlreadyLinked({required String childUid}) {
    return remote.isChildAlreadyLinked(childUid: childUid);
  }

  @override
  Future<String?> getChildParentId({required String childUid}) {
    return remote.getChildParentId(childUid: childUid);
  }

  @override
  Future<List<Map<String, dynamic>>> getParentChildren({required String parentUid}) {
    return remote.getParentChildren(parentUid: parentUid);
  }
}