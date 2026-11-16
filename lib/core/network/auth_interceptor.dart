import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import 'api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required TokenStorage storage, required String baseUrl, required this.sessionVersion, required this.expireSession})
      : _storage = storage, _origin = Uri.parse(baseUrl);
  final TokenStorage _storage;
  final Uri _origin;
  final int Function() sessionVersion;
  final Future<void> Function(int version) expireSession;
  static const _requestVersion = 'movielog.sessionVersion';
  bool isProtected(RequestOptions options) {
    final uri = options.uri;
    final path = uri.path;
    return uri.scheme == _origin.scheme && uri.host == _origin.host && uri.port == _origin.port &&
        (path == '/v7/members/me' || path == '/v7/ratings' || path.startsWith('/v7/ratings/'));
  }
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers.removeWhere((key, value) => key.toLowerCase() == 'authorization');
    if (!isProtected(options)) { handler.next(options); return; }
    final version = sessionVersion();
    options.extra[_requestVersion] = version;
    options.followRedirects = false;
    try {
      final token = await _storage.readAccessToken();
      if (version != sessionVersion()) {
        handler.reject(DioException(requestOptions: options, type: DioExceptionType.cancel, message: '세션이 변경되어 요청이 취소되었습니다.'));
        return;
      }
      if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } catch (_) {
      handler.reject(DioException(requestOptions: options, message: '인증 저장소를 읽지 못했습니다.', error: StateError('Secure storage read failed.')));
    }
  }
  @override
  Future<void> onError(DioException error, ErrorInterceptorHandler handler) async {
    final version = error.requestOptions.extra[_requestVersion];
    if (isProtected(error.requestOptions) && error.response?.statusCode == 401 &&
        isExpiredSessionCode(apiErrorCode(error)) && version is int && version == sessionVersion()) {
      await expireSession(version);
    }
    handler.next(error);
  }
}
