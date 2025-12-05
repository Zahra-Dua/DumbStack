import 'package:parental_control_app/features/user_management/domain/repositories/pairing_repository.dart';

class GetParentChildrenUseCase {
  final PairingRepository repository;
  GetParentChildrenUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call({required String parentUid}) {
    return repository.getParentChildren(parentUid: parentUid);
  }
}
