import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config/tmdb_config.dart';

enum MovieLoadStatus { idle, loading, empty, error, success }

/// Cancel work on route disposal and ignore any late completion, including
/// services that don't actually support transport cancellation.
abstract class MovieRequestViewModel extends ChangeNotifier {
  CancelToken? _activeRequest;
  bool _disposed = false;

  @protected
  CancelToken beginRequest() {
    _activeRequest?.cancel('A new request replaced this request.');
    return _activeRequest = CancelToken();
  }

  @protected
  bool isCurrent(CancelToken token) =>
      !_disposed && identical(token, _activeRequest) && !token.isCancelled;

  @protected
  void notifyState() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _activeRequest?.cancel('The page was disposed.');
    super.dispose();
  }
}

String movieErrorMessage(Object error) {
  if (error is DioException) {
    if (error.error is TmdbConfigurationException) {
      return 'TMDB 연결 설정이 필요해요. .env의 TMDB_ACCESS_TOKEN을 확인해주세요.';
    }
    if (error.response?.statusCode == 401) {
      return 'TMDB 인증에 실패했어요. 설정한 Read Access Token을 확인해주세요.';
    }
    if (error.response?.statusCode == 429) return '요청이 많아요. 잠시 후 다시 시도해주세요.';
  }
  if (error is FormatException) return '영화 정보를 읽지 못했어요. 다시 시도해주세요.';
  return '영화 정보를 불러오지 못했어요. 네트워크를 확인하고 다시 시도해주세요.';
}
