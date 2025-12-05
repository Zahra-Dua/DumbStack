abstract class PairingRepository {
  Future<String> generateParentQRCode({required String parentUid});
  Future<void> linkChildToParent({
    required String parentUid,
    required String firstName,
    required String lastName,
    required String childName,
    required int age,
    required String gender,
    required List<String> hobbies,
  });
  Future<bool> isChildAlreadyLinked({required String childUid});
  Future<String?> getChildParentId({required String childUid});
  Future<List<Map<String, dynamic>>> getParentChildren({required String parentUid});
}