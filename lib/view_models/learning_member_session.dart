import 'package:flutter/foundation.dart';

/// In-memory study identifier, not login authentication.
class LearningMemberSession extends ChangeNotifier {
  int? memberId;
  void setMemberId(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
