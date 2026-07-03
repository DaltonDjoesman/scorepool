import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String? _currentGroupId;
  bool _sessionReady = false;

  String? get currentGroupId => _currentGroupId;
  bool get sessionReady => _sessionReady;

  void setCurrentGroupId(String groupId) {
    if (groupId == _currentGroupId) return;
    _currentGroupId = groupId;
    notifyListeners();
  }

  void clearCurrentGroupId() {
    if (_currentGroupId == null) return;
    _currentGroupId = null;
    notifyListeners();
  }

  void setSessionReady(bool ready) {
    if (_sessionReady == ready) return;
    _sessionReady = ready;
    notifyListeners();
  }
}
