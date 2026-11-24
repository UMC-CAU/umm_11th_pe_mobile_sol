import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/config/movie_log_config.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'support/capturing_adapter.dart';
import 'support/week8_fakes.dart';

void main() {
  test(
    'MovieLog JWT is restricted to configured origin and protected v8 paths',
    () async {
      final storage = MemoryTokenStorage()..token = 'user-token';
      final public = MovieLogClient(baseUrl: 'https://movielog.example');
      final protected = ProtectedMovieLogClient(
        baseUrl: 'https://movielog.example',
        storage: storage,
        sessionVersion: () => 1,
        expireSession: (_) async {},
      );
      final tmdb = TmdbClient(accessToken: 'tmdb-token');
      addTearDown(public.close);
      addTearDown(protected.close);
      addTearDown(tmdb.close);
      final a = CapturingAdapter(),
          b = CapturingAdapter(),
          c = CapturingAdapter();
      public.dio.httpClientAdapter = a;
      protected.dio.httpClientAdapter = b;
      tmdb.dio.httpClientAdapter = c;
      await public.dio.get<dynamic>('/v8/members/1/ratings');
      await protected.dio.get<dynamic>('/v8/members/me');
      await protected.dio.get<dynamic>('/v8/members/1/ratings');
      await protected.dio.get<dynamic>('https://other.example/v8/favorites');
      await protected.dio.get<dynamic>('/v8/favorites');
      await protected.dio.post<dynamic>(
        '/v8/favorites',
        data: {'movieId': 550},
      );
      await protected.dio.get<dynamic>('/v8/favorites/550');
      await protected.dio.delete<dynamic>('/v8/favorites/550');
      await protected.dio.post<dynamic>('/v8/auth/login');
      await tmdb.dio.get<dynamic>('/movie/popular');
      expect(a.requests.single.headers.containsKey('Authorization'), isFalse);
      expect(b.requests[0].headers['Authorization'], 'Bearer user-token');
      expect(b.requests[1].headers.containsKey('Authorization'), isFalse);
      expect(b.requests[2].headers.containsKey('Authorization'), isFalse);
      expect(c.requests.single.headers['Authorization'], 'Bearer tmdb-token');
      for (final request in b.requests.getRange(3, 7)) {
        expect(request.headers['Authorization'], 'Bearer user-token');
        expect(request.followRedirects, isFalse);
      }
      expect(b.requests.last.headers.containsKey('Authorization'), isFalse);
      await expectLater(
        tmdb.dio.get<dynamic>('https://other.example/movie/popular'),
        throwsA(isA<DioException>()),
      );
      expect(c.requests.length, 1);
    },
  );
  test('missing MovieLog address fails before HTTP', () async {
    final client = MovieLogClient(baseUrl: '');
    addTearDown(client.close);
    final adapter = CapturingAdapter();
    client.dio.httpClientAdapter = adapter;
    await expectLater(
      client.dio.get<dynamic>('/test'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'cause',
          isA<MovieLogConfigurationException>(),
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test('only an expired current session is closed once', () async {
    var version = 1;
    final expired = <int>[];
    final client = ProtectedMovieLogClient(
      baseUrl: 'https://movielog.example',
      storage: MemoryTokenStorage()..token = 'test-token',
      sessionVersion: () => version,
      expireSession: (expiredVersion) async {
        expired.add(expiredVersion);
        version++;
      },
    );
    addTearDown(client.close);
    final api = FavoriteApiService(client.dio, sessionVersion: () => version);
    final adapter = CapturingAdapter()
      ..status = 401
      ..body = {'code': 'AUTH401_4'};
    client.dio.httpClientAdapter = adapter;

    final queuedAssertion = expectLater(
      api.getStatus(550),
      throwsA(
        isA<DioException>().having(
          (error) => error.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    version++;
    await queuedAssertion;
    expect(adapter.requests, isEmpty);

    final received = Completer<void>();
    final release = Completer<void>();
    adapter.beforeRespond = () {
      received.complete();
      return release.future;
    };
    final oldAssertion = expectLater(
      api.getStatus(550),
      throwsA(isA<DioException>()),
    );
    await received.future;
    version++;
    release.complete();
    await oldAssertion;
    expect(expired, isEmpty);

    adapter.beforeRespond = null;
    adapter.status = 403;
    await expectLater(api.getStatus(550), throwsA(isA<DioException>()));
    adapter.status = 401;
    adapter.body = {'code': 'AUTH401_1'};
    await expectLater(api.getStatus(550), throwsA(isA<DioException>()));
    expect(expired, isEmpty);

    adapter.body = {'code': 'AUTH401_4'};
    await Future.wait([
      expectLater(api.getStatus(550), throwsA(isA<DioException>())),
      expectLater(api.getStatus(551), throwsA(isA<DioException>())),
    ]);
    expect(expired, [3]);
  });
}
