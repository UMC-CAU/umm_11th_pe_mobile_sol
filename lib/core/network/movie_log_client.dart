import 'package:dio/dio.dart';

import '../config/movie_log_config.dart';

/// A distinct Provider type prevents a MovieLog Service from accidentally
/// resolving the TMDB Dio instance when both clients are in the widget tree.
class MovieLogClient {
  MovieLogClient({String? baseUrl, String? accessToken})
    : dio = createMovieLogClient(baseUrl: baseUrl, accessToken: accessToken);

  final Dio dio;

  /// Pass the MovieLog login response's token here. This never reads or changes
  /// TMDB_ACCESS_TOKEN. Clear it on logout with setAccessToken(null).
  void setAccessToken(String? accessToken) {
    final token = accessToken?.trim() ?? '';
    if (token.isEmpty) {
      dio.options.headers.remove('Authorization');
    } else {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  void close() => dio.close(force: true);
}

/// The backend contract/URLs for members, ratings and favorites are added in
/// their own Services later. Never reuse the TMDB token or client for them.
Dio createMovieLogClient({String? baseUrl, String? accessToken}) {
  final url = (baseUrl ?? MovieLogConfig.baseUrl).trim();
  final token = accessToken?.trim() ?? '';
  final dio = Dio(
    BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
      headers: {
        'accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (url.isEmpty) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: const MovieLogConfigurationException(),
              message: 'MOVIELOG_API_BASE_URL 설정이 필요합니다.',
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
