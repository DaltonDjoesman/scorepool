import 'package:shared_preferences/shared_preferences.dart';

class GroupSelectionStore {
  static String _keyFor(String uid) => 'current_group_id_$uid';

  Future<String?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFor(uid));
  }

  Future<void> save(String uid, String? groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(uid);
    if (groupId == null || groupId.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, groupId);
  }
}
