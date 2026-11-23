class SessionGuard {
  int _generation = 0;
  String? _accountId;

  int get generation => _generation;
  String? get accountId => _accountId;

  void replaceAccount(String? accountId) {
    _accountId = accountId;
    _generation++;
  }

  bool isCurrent(int generation, String accountId) =>
      generation == _generation && accountId == _accountId;
}
