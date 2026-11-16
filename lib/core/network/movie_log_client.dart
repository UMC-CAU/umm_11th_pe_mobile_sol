import 'package:dio/dio.dart';
import '../config/movie_log_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

class MovieLogClient {
  MovieLogClient({String? baseUrl}) : dio = createMovieLogClient(baseUrl: baseUrl);
  final Dio dio;
  void close() => dio.close(force: true);
}
class ProtectedMovieLogClient {
  ProtectedMovieLogClient({String? baseUrl, required TokenStorage storage, required int Function() sessionVersion, required Future<void> Function(int) expireSession})
      : dio = createAuthMovieLogClient(baseUrl: baseUrl, storage: storage, sessionVersion: sessionVersion, expireSession: expireSession);
  final Dio dio;
  void close() => dio.close(force: true);
}
Dio createMovieLogClient({String? baseUrl}) {
  final url = (baseUrl ?? MovieLogConfig.baseUrl).trim();
  final dio = Dio(BaseOptions(baseUrl: url, connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10), contentType: Headers.jsonContentType, headers: {'accept': 'application/json'}));
  if (url.isEmpty) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.reject(DioException(requestOptions: options, error: const MovieLogConfigurationException(), message: 'MOVIELOG_API_BASE_URL 설정이 필요합니다.'));
    }));
  }
  return dio;
}
Dio createAuthMovieLogClient({String? baseUrl, required TokenStorage storage, required int Function() sessionVersion, required Future<void> Function(int) expireSession}) {
  final url = (baseUrl ?? MovieLogConfig.baseUrl).trim();
  final dio = createMovieLogClient(baseUrl: url);
  dio.interceptors.add(AuthInterceptor(storage: storage, baseUrl: url, sessionVersion: sessionVersion, expireSession: expireSession));
  return dio;
}
