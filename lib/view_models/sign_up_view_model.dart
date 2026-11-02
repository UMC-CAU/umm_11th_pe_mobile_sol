import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/validation/sign_up_validators.dart';
import '../data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final MemberCheckService _service;

  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String? emailErrorText;
  String _currentNickname = '';
  String _currentEmail = '';
  String? _duplicatedNickname;
  String? _duplicatedEmail;
  int _nicknameVersion = 0;
  int _emailVersion = 0;
  bool _disposed = false;

  bool get canCheckNickname =>
      !_disposed &&
      SignUpValidators.nickname(_currentNickname) == null &&
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      !_disposed &&
      SignUpValidators.email(_currentEmail) == null &&
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  bool get checksPassed =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  void onNicknameChanged(String value) {
    if (_disposed) return;
    _currentNickname = value.trim();
    _nicknameVersion++;
    final duplicated = _currentNickname == _duplicatedNickname;
    nicknameCheckStatus = duplicated
        ? CheckStatus.duplicated
        : CheckStatus.idle;
    nicknameErrorText = duplicated ? '이미 사용 중인 닉네임입니다.' : null;
    notifyListeners();
  }

  void onEmailChanged(String value) {
    if (_disposed) return;
    _currentEmail = value.trim();
    _emailVersion++;
    final duplicated = _currentEmail == _duplicatedEmail;
    emailCheckStatus = duplicated ? CheckStatus.duplicated : CheckStatus.idle;
    emailErrorText = duplicated ? '이미 사용 중인 이메일입니다.' : null;
    notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();
    if (!canCheckNickname || requested != _currentNickname) return;
    final version = ++_nicknameVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();
    try {
      final available = await _service.checkNickname(requested);
      if (_disposed || version != _nicknameVersion) return;
      nicknameCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      nicknameErrorText = available ? null : '이미 사용 중인 닉네임입니다.';
      if (!available) _duplicatedNickname = requested;
    } on DioException {
      if (_disposed || version != _nicknameVersion) return;
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    } on FormatException {
      if (_disposed || version != _nicknameVersion) return;
      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '확인 응답을 읽지 못했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _nicknameVersion) notifyListeners();
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();
    if (!canCheckEmail || requested != _currentEmail) return;
    final version = ++_emailVersion;
    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();
    try {
      final available = await _service.checkEmail(requested);
      if (_disposed || version != _emailVersion) return;
      emailCheckStatus = available
          ? CheckStatus.available
          : CheckStatus.duplicated;
      emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';
      if (!available) _duplicatedEmail = requested;
    } on DioException {
      if (_disposed || version != _emailVersion) return;
      emailCheckStatus = CheckStatus.error;
      emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    } on FormatException {
      if (_disposed || version != _emailVersion) return;
      emailCheckStatus = CheckStatus.error;
      emailErrorText = '확인 응답을 읽지 못했습니다. 다시 시도해 주세요.';
    }
    if (!_disposed && version == _emailVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameVersion++;
    _emailVersion++;
    super.dispose();
  }
}
