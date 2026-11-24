import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/validation/sign_up_validators.dart';
import '../data/services/sign_up_service.dart';
import '../data/models/create_member_request.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

enum SubmitStatus { idle, submitting, success, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final SignUpService _service;

  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId;
  String? passwordErrorText;
  String? snackbarMessage;

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
      submitStatus != SubmitStatus.submitting &&
      SignUpValidators.nickname(_currentNickname) == null &&
      nicknameCheckStatus != CheckStatus.checking &&
      nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      !_disposed &&
      submitStatus != SubmitStatus.submitting &&
      SignUpValidators.email(_currentEmail) == null &&
      emailCheckStatus != CheckStatus.checking &&
      emailCheckStatus != CheckStatus.duplicated;

  bool get checksPassed =>
      nicknameCheckStatus == CheckStatus.available &&
      emailCheckStatus == CheckStatus.available;

  void onNicknameChanged(String value) {
    if (_disposed) return;
    snackbarMessage = null;
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
    snackbarMessage = null;
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

  void onPasswordChanged() {
    if (_disposed) return;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (_disposed ||
        submitStatus == SubmitStatus.submitting ||
        !checksPassed ||
        request.nickname.trim() != _currentNickname ||
        request.email.trim() != _currentEmail) {
      return;
    }
    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();
    try {
      final response = await _service.signUp(request);
      if (_disposed) return;
      final id = response.result?.memberId;
      if (!response.isSuccess || id == null || id <= 0) {
        throw const FormatException('Missing memberId.');
      }
      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      final text = serverErrorMessage(
        error,
        fallback: '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.',
      );
      if (error.response?.statusCode == 400 && text.contains('비밀번호')) {
        passwordErrorText = text;
      } else {
        snackbarMessage = text;
      }
    } catch (_) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      snackbarMessage = '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameVersion++;
    _emailVersion++;
    super.dispose();
  }
}
