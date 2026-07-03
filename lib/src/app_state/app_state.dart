import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String? _currentGroupId;

  String? get currentGroupId => _currentGroupId;

  void setCurrentGroupId(String groupId) {
    if (groupId == _currentGroupId) return;
    _currentGroupId = groupId;
    notifyListeners();
  }
}
