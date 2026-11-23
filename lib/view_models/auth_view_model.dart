import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_error.dart';
import '../core/storage/token_storage.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);
  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;
  AuthStatus status = AuthStatus.initializing;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  MemberInfo? member;
  String? message;
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;
  bool storageCleanupFailed = false;
  int _version = 0;
  int get sessionVersion => _version;
  bool _disposed = false;
  Future<void>? _tokenWrite;
  bool _current(int version) => !_disposed && version == _version;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> restoreSession() async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_version;
    status = AuthStatus.initializing;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    message = null;
    _notify();
    String? token;
    try {
      token = await _storage.readAccessToken();
    } catch (_) {
      if (!_current(version)) return;
      status = AuthStatus.retryRequired;
      message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
      _notify();
      return;
    }
    if (!_current(version)) return;
    if (token == null || token.isEmpty) {
      status = AuthStatus.signedOut;
      _notify();
      return;
    }
    try {
      final result = await _memberApi.fetchMe();
      if (!_current(version)) return;
      member = result;
      memberStatus = MemberLoadStatus.success;
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_current(version)) return;
      if (error.response?.statusCode == 401 &&
          isExpiredSessionCode(apiErrorCode(error))) {
        await expireSession(version);
        return;
      }
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_current(version)) return;
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    }
    _notify();
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        storageCleanupFailed ||
        status == AuthStatus.authenticating) {
      return;
    }
    final version = ++_version;
    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    message = null;
    sessionExpired = false;
    _notify();
    LoginResult result;
    try {
      result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );
    } on DioException catch (error) {
      if (!_current(version)) return;
      status = AuthStatus.signedOut;
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
      _notify();
      return;
    } catch (_) {
      if (!_current(version)) return;
      status = AuthStatus.signedOut;
      message = '로그인 응답을 확인하지 못했어요. 다시 시도해 주세요.';
      _notify();
      return;
    }
    if (!_current(version)) return;
    try {
      final write = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = write;
      try {
        await write;
      } finally {
        if (identical(_tokenWrite, write)) _tokenWrite = null;
      }
      if (!_current(version)) return;
      status = AuthStatus.signedIn;
    } catch (_) {
      if (!_current(version)) return;
      await _clearSession(expired: false);
      if (_disposed) return;
      message = storageCleanupFailed
          ? '인증 정보를 정리하지 못했어요. 삭제를 다시 시도해 주세요.'
          : '로그인 정보를 안전하게 저장하지 못했어요. 다시 시도해 주세요.';
    }
    _notify();
  }

  Future<void> loadMember({bool force = false}) async {
    if (_disposed ||
        status != AuthStatus.signedIn ||
        memberStatus == MemberLoadStatus.loading ||
        (member != null && !force)) {
      return;
    }
    final version = _version;
    memberStatus = MemberLoadStatus.loading;
    _notify();
    try {
      final result = await _memberApi.fetchMe();
      if (!_current(version)) return;
      member = result;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_current(version)) return;
      if (error.response?.statusCode == 401 &&
          isExpiredSessionCode(apiErrorCode(error))) {
        await expireSession(version);
        return;
      }
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_current(version)) return;
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    _notify();
  }

  void updateMember(MemberInfo updated, int version) {
    if (!_current(version) || status != AuthStatus.signedIn) return;
    member = updated;
    memberStatus = MemberLoadStatus.success;
    _notify();
  }

  Future<void> expireSession(int version) async {
    if (_current(version)) await _clearSession(expired: true);
  }

  Future<void> logout() => _clearSession(expired: false);
  Future<void> retryStorageCleanup() => _clearSession(expired: false);
  Future<void> _clearSession({required bool expired}) async {
    if (_disposed || storageCleanupInProgress) return;
    final version = ++_version;
    storageCleanupInProgress = true;
    status = AuthStatus.signedOut;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    message = null;
    _notify();
    try {
      try {
        await _tokenWrite;
      } catch (_) {
        /* Still attempt deletion. */
      }
      await _storage.deleteAccessToken();
      storageCleanupFailed = false;
    } catch (_) {
      storageCleanupFailed = true;
      if (_current(version)) message = '저장된 인증 정보를 지우지 못했어요. 삭제를 다시 시도해 주세요.';
    } finally {
      storageCleanupInProgress = false;
      if (_current(version)) _notify();
    }
  }

  bool takeExpiredNotice() {
    if (!sessionExpired) return false;
    sessionExpired = false;
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
