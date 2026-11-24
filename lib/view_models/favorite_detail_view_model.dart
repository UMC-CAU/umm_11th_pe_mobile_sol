import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required FavoriteApiService api,
    required SessionGuard session,
    required String accountId,
    required this.movieId,
  }) : _api = api,
       _session = session,
       _accountId = accountId,
       _generation = session.generation;

  final FavoriteApiService _api;
  final SessionGuard _session;
  final String _accountId;
  final int _generation;
  final int movieId;

  bool? _favorite;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _needsStatusCheck = false;
  String? _errorMessage;

  bool get isFavorite => _favorite ?? false;
  bool get hasLoadedStatus => _favorite != null;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isCurrent =>
      !isDisposed && _session.isCurrent(_generation, _accountId);

  Future<void> load() async {
    if (!isCurrent || _isLoading || _isSaving) return;
    _isLoading = true;
    _errorMessage = null;
    notifyIfAlive();
    await _confirmStatus();
    if (!isCurrent) return;
    _isLoading = false;
    notifyIfAlive();
  }

  Future<bool> _confirmStatus() async {
    if (!isCurrent) return false;
    try {
      final status = await _api.getStatus(movieId);
      if (!isCurrent) return false;
      _favorite = status.isFavorite;
      _needsStatusCheck = false;
      return true;
    } catch (_) {
      if (isCurrent) _errorMessage = '즐겨찾기 여부를 확인하지 못했어요.';
      return false;
    }
  }

  Future<String?> toggle() async {
    final before = _favorite;
    if (!isCurrent || _isLoading || _isSaving || before == null) return null;
    _isSaving = true;
    _errorMessage = null;
    notifyIfAlive();
    try {
      if (!isCurrent) return null;
      if (_needsStatusCheck) {
        if (!await _confirmStatus() || !isCurrent) {
          return isCurrent ? _errorMessage : null;
        }
        if (_favorite != before) return _synchronizedMessage;
      }
      if (before) {
        await _api.remove(movieId);
      } else {
        await _api.add(movieId);
      }
      if (!isCurrent) return null;
      _favorite = !before;
      return before ? '즐겨찾기에서 삭제했어요.' : '즐겨찾기에 추가했어요.';
    } on DioException catch (error) {
      if (!isCurrent) return null;
      final code = apiErrorCode(error);
      final status = error.response?.statusCode;
      if ((status == 409 && code == 'FAVORITE409_1') ||
          (status == 404 && code == 'FAVORITE404_1')) {
        _needsStatusCheck = true;
        if (!await _confirmStatus()) return isCurrent ? _errorMessage : null;
        return _synchronizedMessage;
      }
      if (status == 404 && code == 'MEMBER404_1') {
        return _errorMessage = '회원 정보를 찾지 못했어요.';
      }
      // A lost response can leave the server with the requested change.
      _needsStatusCheck = status == null || status >= 500;
      return _writeFailed(before);
    } catch (_) {
      if (!isCurrent) return null;
      _needsStatusCheck = true;
      return _writeFailed(before);
    } finally {
      if (isCurrent) {
        _isSaving = false;
        notifyIfAlive();
      }
    }
  }

  String get _synchronizedMessage =>
      isFavorite ? '이미 즐겨찾기에 등록된 영화예요.' : '현재 즐겨찾기에 등록되어 있지 않아요.';

  String _writeFailed(bool wasFavorite) => _errorMessage = wasFavorite
      ? '즐겨찾기 해제에 실패했어요. 다시 시도해 주세요.'
      : '즐겨찾기 등록에 실패했어요. 다시 시도해 주세요.';
}
