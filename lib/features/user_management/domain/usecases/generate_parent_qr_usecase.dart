import 'package:parental_control_app/features/user_management/domain/repositories/pairing_repository.dart';

class GenerateParentQRUseCase {
  final PairingRepository repository;
  GenerateParentQRUseCase(this.repository);

  Future<String> call({required String parentUid}) {
    return repository.generateParentQRCode(parentUid: parentUid);
  }
}
