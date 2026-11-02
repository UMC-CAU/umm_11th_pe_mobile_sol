import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/config/movie_log_config.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/models/check_result.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

import 'support/capturing_adapter.dart';

void main() {
  test('v5 availability is read without a result wrapper', () {
    expect(CheckResult.fromJson({'available': false}).available, isFalse);
    expect(
      () => CheckResult.fromJson({
        'result': {'available': true},
      }),
      throwsFormatException,
    );
  });

  test('rating DTO preserves nullable comment and timestamps', () {
    final rating = RatingDto.fromJson({
      'ratingId': 12,
      'movieId': 550,
      'score': 5,
      'comment': null,
      'createdAt': '2026-09-06T12:14:03.000Z',
      'updatedAt': '2026-09-07T12:14:03.000Z',
    });
    expect(rating.movieId, 550);
    expect(rating.comment, isNull);
    expect(rating.createdAt.isUtc, isTrue);
    expect(rating.updatedAt!.day, 7);
  });

  test('member service trims and encodes an entire path segment', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    addTearDown(() => dio.close(force: true));
    final adapter = CapturingAdapter()..body = {'available': true};
    dio.httpClientAdapter = adapter;
    final service = MemberCheckService(dio);
    expect(await service.checkNickname('  한솔/#?  '), isTrue);
    expect(await service.checkEmail(' sol+study@example.com '), isTrue);
    expect(adapter.requests.first.uri.pathSegments.last, '한솔/#?');
    expect(
      adapter.requests.last.uri.pathSegments.last,
      'sol+study@example.com',
    );
    expect(adapter.requests.every((r) => r.method == 'GET'), isTrue);
    expect(adapter.requests.first.uri.query, isEmpty);
    expect(adapter.requests.first.uri.fragment, isEmpty);
  });

  test(
    'rating service reads bare arrays, keeps empty separate from HTTP 404',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      addTearDown(() => dio.close(force: true));
      final adapter = CapturingAdapter()..body = [];
      dio.httpClientAdapter = adapter;
      final service = RatingApiService(dio);
      expect(await service.fetchMyRatings(1), isEmpty);
      expect(adapter.requests.single.path, '/v5/members/1/ratings');
      adapter.status = 404;
      adapter.body = {
        'message': '존재하지 않는 유저입니다.',
        'error': 'Not Found',
        'statusCode': 404,
      };
      await expectLater(
        service.fetchMyRatings(1),
        throwsA(isA<DioException>()),
      );
      adapter.status = 200;
      adapter.body = {'result': []};
      await expectLater(service.fetchMyRatings(1), throwsFormatException);
    },
  );

  test('workbook default client has no TMDB credentials', () {
    final client = MovieLogClient();
    addTearDown(client.close);
    expect(client.dio.options.baseUrl, MovieLogConfig.workbookBaseUrl);
    expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
  });
}
