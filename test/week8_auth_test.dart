import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/router/app_router.dart';
import 'support/capturing_adapter.dart';
import 'support/week8_fakes.dart';
const memberJson = {'isSuccess': true, 'code': 'OK', 'message': 'ok', 'result': {'email': 'a@example.com', 'nickname': '한솔', 'createdAt': '2026-11-01T00:00:00Z'}};
void main() {
  test('restoration confirms token with GET me before becoming signed in', () async {
    final storage = MemoryTokenStorage()..token = 'stored-token'; final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    final adapter = CapturingAdapter()..body = memberJson; dio.httpClientAdapter = adapter;
    final auth = AuthViewModel(AuthApiService(Dio()), MemberApiService(dio), storage); addTearDown(auth.dispose); addTearDown(() => dio.close(force: true));
    await auth.restoreSession(); expect(adapter.requests.single.path, '/v7/members/me'); expect(auth.status, AuthStatus.signedIn); expect(auth.member?.nickname, '한솔');
  });
  test('restoration server failure retains token and exposes retry', () async {
    final storage = MemoryTokenStorage()..token = 'stored-token'; final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    final adapter = CapturingAdapter()..status = 500; dio.httpClientAdapter = adapter;
    final auth = AuthViewModel(AuthApiService(Dio()), MemberApiService(dio), storage); addTearDown(auth.dispose); addTearDown(() => dio.close(force: true));
    await auth.restoreSession(); expect(auth.status, AuthStatus.retryRequired); expect(storage.token, 'stored-token');
  });
  test('invalid token clears session while login error is not expiration', () async {
    final storage = MemoryTokenStorage()..token = 'invalid'; final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    final adapter = CapturingAdapter()..status = 401..body = {'code': 'AUTH401_3'}; dio.httpClientAdapter = adapter;
    final auth = AuthViewModel(AuthApiService(dio), MemberApiService(dio), storage); addTearDown(auth.dispose); addTearDown(() => dio.close(force: true));
    await auth.restoreSession(); expect(auth.status, AuthStatus.signedOut); expect(storage.token, isNull); expect(auth.takeExpiredNotice(), isTrue); expect(auth.takeExpiredNotice(), isFalse);
    adapter.body = {'code': 'AUTH401_1'}; await auth.login('a@example.com', 'wrong'); expect(auth.status, AuthStatus.signedOut); expect(auth.sessionExpired, isFalse); expect(auth.message, contains('비밀번호'));
  });
  test('routing protects screens during initialization and after logout', () {
    expect(authRedirect(AuthStatus.initializing, '/home'), '/'); expect(authRedirect(AuthStatus.retryRequired, '/my'), '/'); expect(authRedirect(AuthStatus.signedOut, '/my/ratings'), '/login'); expect(authRedirect(AuthStatus.signedOut, '/signup'), isNull); expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
  });
}
