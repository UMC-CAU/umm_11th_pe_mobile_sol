import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/tmdb_config.dart';
import 'tmdb_logging_interceptor.dart';

/// Its own Provider type keeps the TMDB Dio separate from MovieLogClient.
class TmdbClient {
  TmdbClient({String? accessToken})
    : dio = createTmdbClient(accessToken: accessToken);

  final Dio dio;

  void close() => dio.close(force: true);
}

/// This client is only for TMDB. MovieLog member/rating endpoints must use
/// their own client and authentication.
Dio createTmdbClient({String? accessToken}) {
  final token = (accessToken ?? TmdbConfig.accessToken).trim();
  final origin = Uri.parse(TmdbConfig.baseUrl);
  final dio = Dio(
    BaseOptions(
      baseUrl: TmdbConfig.baseUrl,
      followRedirects: false,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(TmdbLoggingInterceptor(accessToken: token));
  }
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final uri = options.uri;
        if (uri.scheme != origin.scheme ||
            uri.host != origin.host ||
            uri.port != origin.port) {
          handler.reject(
            DioException(
              requestOptions: options,
              message: 'TMDB 서버로만 영화 정보를 요청할 수 있습니다.',
            ),
          );
          return;
        }
        if (token.isEmpty) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: const TmdbConfigurationException(),
              message: 'TMDB_ACCESS_TOKEN 설정이 필요합니다.',
            ),
          );
          return;
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}
