import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/movie_log_config.dart';
import '../storage/token_storage.dart';
import 'api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage storage,
    required String baseUrl,
    required this.sessionVersion,
    required this.expireSession,
  }) : _storage = storage,
       _origin = Uri.parse(baseUrl);

  final TokenStorage _storage;
  final Uri _origin;
  final int Function() sessionVersion;
  final Future<void> Function(int version) expireSession;
  static const expectedSessionVersion = 'movielog.expectedSessionVersion';
  static const _requestVersion = 'movielog.sessionVersion';
  static const _api = MovieLogConfig.apiPrefix;
  static final _rating = RegExp(
    r'^'
    '$_api'
    r'/ratings/[1-9]\d*$',
  );
  static final _favorite = RegExp(
    r'^'
    '$_api'
    r'/favorites/[1-9]\d*$',
  );
  static final _logCode = RegExp(
    r'^(AUTH|FAVORITE|MEMBER|COMMON)\d{3}(_\d+)?$',
  );

  bool isProtected(RequestOptions options) {
    final uri = options.uri;
    if (uri.scheme != _origin.scheme ||
        uri.host != _origin.host ||
        uri.port != _origin.port) {
      return false;
    }
    final path = uri.path;
    final method = options.method.toUpperCase();
    return (path == '$_api/members/me' &&
            (method == 'GET' || method == 'PATCH')) ||
        (path == '$_api/ratings' && method == 'POST') ||
        (_rating.hasMatch(path) && (method == 'PATCH' || method == 'DELETE')) ||
        _isFavorite(options);
  }

  bool _isFavorite(RequestOptions options) {
    final path = options.uri.path;
    final method = options.method.toUpperCase();
    return (path == '$_api/favorites' &&
            (method == 'GET' || method == 'POST')) ||
        (_favorite.hasMatch(path) && (method == 'GET' || method == 'DELETE'));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.removeWhere(
      (key, value) => key.toLowerCase() == 'authorization',
    );
    if (!isProtected(options)) {
      handler.next(options);
      return;
    }
    final version = sessionVersion();
    final expected = options.extra[expectedSessionVersion];
    if (expected is int && expected != version) {
      handler.reject(_sessionChanged(options));
      return;
    }
    options.extra[_requestVersion] = version;
    options.followRedirects = false;
    try {
      final token = await _storage.readAccessToken();
      if (version != sessionVersion()) {
        handler.reject(_sessionChanged(options));
        return;
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          message: '인증 저장소를 읽지 못했습니다.',
          error: StateError('Secure storage read failed.'),
        ),
      );
    }
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final version = options.extra[_requestVersion];
    final code = apiErrorCode(err);
    _log(options, err.response?.statusCode, code);
    if (isProtected(options) &&
        err.response?.statusCode == 401 &&
        isExpiredSessionCode(code) &&
        version is int &&
        version == sessionVersion()) {
      await expireSession(version);
    }
    handler.next(err);
  }

  DioException _sessionChanged(RequestOptions options) => DioException(
    requestOptions: options,
    type: DioExceptionType.cancel,
    message: '세션이 변경되어 요청이 취소되었습니다.',
  );

  void _log(RequestOptions options, int? status, [String? code]) {
    if (!kDebugMode ||
        !options.extra.containsKey(_requestVersion) ||
        !_isFavorite(options)) {
      return;
    }
    final suffix = code != null && _logCode.hasMatch(code) ? ' $code' : '';
    debugPrint(
      '[MovieLog] ${options.method} ${options.uri.path} → ${status ?? '연결 오류'}$suffix',
    );
  }
}
