import 'package:shared_preferences/shared_preferences.dart';

class UserLocalDatasource {
  Future<void> saveUserType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_type', type);
  }

  Future<void> saveUserUID(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_uid', uid);
  }

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type');
  }
}
