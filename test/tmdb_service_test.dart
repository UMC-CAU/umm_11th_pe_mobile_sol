import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/network/tmdb_logging_interceptor.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

import 'support/capturing_adapter.dart';

void main() {
  test(
    'all omits with_genres, multi uses OR, and client attaches bearer auth',
    () async {
      final dio = createTmdbClient(accessToken: 'test-only-token');
      final adapter = CapturingAdapter();
      dio.httpClientAdapter = adapter;
      final service = TmdbMovieService(dio);
      await service.discoverMovies();
      await service.discoverMovies(page: 3, genreIds: [28, 18]);
      expect(
        adapter.requests[0].queryParameters.containsKey('with_genres'),
        isFalse,
      );
      expect(adapter.requests[1].queryParameters['with_genres'], '28|18');
      expect(adapter.requests[1].queryParameters['page'], 3);
      expect(adapter.requests[1].queryParameters['language'], 'ko-KR');
      expect(
        adapter.requests[1].headers['Authorization'],
        'Bearer test-only-token',
      );
      expect(adapter.requests[1].path, '/discover/movie');
      dio.close();
    },
  );

  test(
    'popular and genre service paths convert their own response shapes',
    () async {
      final dio = Dio(BaseOptions(baseUrl: TmdbConfig.baseUrl));
      final adapter = CapturingAdapter();
      dio.httpClientAdapter = adapter;
      final service = TmdbMovieService(dio);
      await service.fetchPopular();
      expect(adapter.requests.last.path, '/movie/popular');
      adapter.body = {
        'genres': [
          {'id': 28, 'name': '액션'},
        ],
      };
      final genres = await service.fetchGenres();
      expect(adapter.requests.last.path, '/genre/movie/list');
      expect(genres.single.id, 28);
      dio.close();
    },
  );

  test('missing token fails before HTTP without exposing a secret', () async {
    final dio = createTmdbClient(accessToken: '');
    final adapter = CapturingAdapter();
    dio.httpClientAdapter = adapter;
    await expectLater(
      TmdbMovieService(dio).fetchPopular(),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'cause',
          isA<TmdbConfigurationException>(),
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
    dio.close();
  });

  test(
    'request, response and error logs redact headers, URL, body and error message',
    () async {
      const secret = 'not-a-real-credential-123';
      final messages = <String>[];
      final dio = Dio(
        BaseOptions(
          baseUrl: TmdbConfig.baseUrl,
          headers: {'Authorization': 'Bearer $secret'},
        ),
      );
      dio.interceptors.add(
        TmdbLoggingInterceptor(accessToken: secret, log: messages.add),
      );
      final adapter = CapturingAdapter()
        ..body = {
          'echo': secret,
          'nested': {'access_token': 'another-secret'},
        };
      dio.httpClientAdapter = adapter;
      await dio.get<dynamic>(
        '/discover/movie',
        queryParameters: {'api_key': 'query-secret', 'page': 1},
      );
      adapter.status = 401;
      await expectLater(
        dio.get<dynamic>('/movie/popular'),
        throwsA(isA<DioException>()),
      );
      final output = messages.join('\n');
      expect(output, contains('[TMDB][REQUEST]'));
      expect(output, contains('[TMDB][RESPONSE]'));
      expect(output, contains('[TMDB][ERROR]'));
      expect(output, contains('/movie/popular'));
      expect(output, contains('401'));
      expect(output, contains('REDACTED'));
      for (final value in [secret, 'another-secret', 'query-secret']) {
        expect(output, isNot(contains(value)));
      }
      // Redaction does not corrupt the real outgoing authorization header.
      expect(adapter.requests.first.headers['Authorization'], 'Bearer $secret');
      dio.close();
    },
  );

  test('disabled logging writes nothing for success or error', () async {
    final messages = <String>[];
    final dio = Dio(BaseOptions(baseUrl: TmdbConfig.baseUrl));
    dio.interceptors.add(
      TmdbLoggingInterceptor(
        accessToken: 'test-only',
        enabled: false,
        log: messages.add,
      ),
    );
    final adapter = CapturingAdapter();
    dio.httpClientAdapter = adapter;
    await dio.get<dynamic>('/movie/popular');
    adapter.status = 401;
    await expectLater(
      dio.get<dynamic>('/movie/popular'),
      throwsA(isA<DioException>()),
    );
    expect(messages, isEmpty);
    dio.close();
  });
}
