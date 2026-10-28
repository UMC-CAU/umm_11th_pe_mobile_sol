import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/config/movie_log_config.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';

import 'support/capturing_adapter.dart';

void main() {
  test(
    'TMDB and MovieLog requests have independent hosts and credentials',
    () async {
      final tmdb = TmdbClient(accessToken: 'test-tmdb-token');
      final movieLog = MovieLogClient(
        baseUrl: 'https://movielog.example/api',
        accessToken: 'test-login-token',
      );
      addTearDown(tmdb.close);
      addTearDown(movieLog.close);
      final tmdbAdapter = CapturingAdapter();
      final movieLogAdapter = CapturingAdapter();
      tmdb.dio.httpClientAdapter = tmdbAdapter;
      movieLog.dio.httpClientAdapter = movieLogAdapter;

      await tmdb.dio.get<dynamic>('/movie/popular');
      await movieLog.dio.get<dynamic>('/test-endpoint');

      expect(tmdb.dio, isNot(same(movieLog.dio)));
      expect(tmdbAdapter.requests.single.uri.host, 'api.themoviedb.org');
      expect(movieLogAdapter.requests.single.uri.host, 'movielog.example');
      expect(
        tmdbAdapter.requests.single.headers['Authorization'],
        'Bearer test-tmdb-token',
      );
      expect(
        movieLogAdapter.requests.single.headers['Authorization'],
        'Bearer test-login-token',
      );
    },
  );

  test(
    'MovieLog never inherits the TMDB token when no login token was supplied',
    () async {
      final tmdb = TmdbClient(accessToken: 'test-tmdb-token');
      final movieLog = MovieLogClient(baseUrl: 'https://movielog.example/api');
      addTearDown(tmdb.close);
      addTearDown(movieLog.close);
      final adapter = CapturingAdapter();
      movieLog.dio.httpClientAdapter = adapter;
      await movieLog.dio.get<dynamic>('/test-endpoint');
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
      expect(
        tmdb.dio.options.headers['Authorization'],
        'Bearer test-tmdb-token',
      );
    },
  );

  test(
    'MovieLog login and logout change only its own request headers',
    () async {
      final tmdb = TmdbClient(accessToken: 'test-tmdb-token');
      final movieLog = MovieLogClient(baseUrl: 'https://movielog.example/api');
      addTearDown(tmdb.close);
      addTearDown(movieLog.close);
      final adapter = CapturingAdapter();
      movieLog.dio.httpClientAdapter = adapter;
      movieLog.setAccessToken('test-user-token');
      await movieLog.dio.get<dynamic>('/test-endpoint');
      movieLog.setAccessToken(null);
      await movieLog.dio.get<dynamic>('/test-endpoint');
      expect(
        adapter.requests[0].headers['Authorization'],
        'Bearer test-user-token',
      );
      expect(adapter.requests[1].headers.containsKey('Authorization'), isFalse);
      expect(
        tmdb.dio.options.headers['Authorization'],
        'Bearer test-tmdb-token',
      );
    },
  );

  test(
    'missing MovieLog address fails before HTTP instead of requesting TMDB',
    () async {
      final movieLog = MovieLogClient(baseUrl: '');
      addTearDown(movieLog.close);
      final adapter = CapturingAdapter();
      movieLog.dio.httpClientAdapter = adapter;
      await expectLater(
        movieLog.dio.get<dynamic>('/test-endpoint'),
        throwsA(
          isA<DioException>().having(
            (error) => error.error,
            'cause',
            isA<MovieLogConfigurationException>(),
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
      expect(movieLog.dio.options.baseUrl, '');
    },
  );
}
