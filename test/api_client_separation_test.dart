import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/config/movie_log_config.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'support/capturing_adapter.dart';
import 'support/week8_fakes.dart';
void main() {
  test('MovieLog JWT is restricted to configured origin and protected v7 paths', () async {
    final storage = MemoryTokenStorage()..token = 'user-token';
    final public = MovieLogClient(baseUrl: 'https://movielog.example');
    final protected = ProtectedMovieLogClient(baseUrl: 'https://movielog.example', storage: storage, sessionVersion: () => 1, expireSession: (_) async {});
    final tmdb = TmdbClient(accessToken: 'tmdb-token');
    addTearDown(public.close); addTearDown(protected.close); addTearDown(tmdb.close);
    final a = CapturingAdapter(), b = CapturingAdapter(), c = CapturingAdapter();
    public.dio.httpClientAdapter = a; protected.dio.httpClientAdapter = b; tmdb.dio.httpClientAdapter = c;
    await public.dio.get<dynamic>('/v7/members/1/ratings'); await protected.dio.get<dynamic>('/v7/members/me');
    await protected.dio.get<dynamic>('/v7/members/1/ratings'); await protected.dio.get<dynamic>('https://other.example/v7/ratings');
    await tmdb.dio.get<dynamic>('/movie/popular');
    expect(a.requests.single.headers.containsKey('Authorization'), isFalse);
    expect(b.requests[0].headers['Authorization'], 'Bearer user-token'); expect(b.requests[1].headers.containsKey('Authorization'), isFalse);
    expect(b.requests[2].headers.containsKey('Authorization'), isFalse); expect(c.requests.single.headers['Authorization'], 'Bearer tmdb-token');
  });
  test('missing MovieLog address fails before HTTP', () async {
    final client = MovieLogClient(baseUrl: ''); addTearDown(client.close);
    final adapter = CapturingAdapter(); client.dio.httpClientAdapter = adapter;
    await expectLater(client.dio.get<dynamic>('/test'), throwsA(isA<DioException>().having((e) => e.error, 'cause', isA<MovieLogConfigurationException>())));
    expect(adapter.requests, isEmpty);
  });
}
