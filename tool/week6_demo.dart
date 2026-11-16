// Recording only: flutter run -t tool/week6_demo.dart
// --dart-define=DEMO_ROUTE=/signup or /my/ratings
// --dart-define=RATINGS_MODE=success|loading|empty|error
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

void main() => runApp(
  Directionality(
    textDirection: TextDirection.ltr,
    child: Banner(
      message: 'DEMO',
      location: BannerLocation.topEnd,
      child: MovieLogApp(
        initialLocation: const String.fromEnvironment(
          'DEMO_ROUTE',
          defaultValue: '/my',
        ),
        movieService: DemoMovieService(),
        memberCheckService: DemoMemberCheckService(),
        ratingApiService: DemoRatingApiService(),
      ),
    ),
  ),
);

class DemoMemberCheckService extends MemberCheckService {
  DemoMemberCheckService() : super(Dio());

  Future<bool> _check(
    String value, {
    required String duplicate,
    required String failure,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (value.trim() == failure) {
      throw DioException(
        requestOptions: RequestOptions(path: '/demo'),
        type: DioExceptionType.connectionError,
      );
    }
    return value.trim() != duplicate;
  }

  @override
  Future<bool> checkNickname(String nickname) =>
      _check(nickname, duplicate: '중복닉네임', failure: '오류닉네임');

  @override
  Future<bool> checkEmail(String email) => _check(
    email,
    duplicate: 'taken@example.com',
    failure: 'error@example.com',
  );
}

class DemoRatingApiService extends RatingApiService {
  DemoRatingApiService() : super(Dio());

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    const mode = String.fromEnvironment(
      'RATINGS_MODE',
      defaultValue: 'success',
    );
    if (mode == 'loading') return Completer<List<RatingDto>>().future;
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mode == 'error') {
      throw DioException(
        requestOptions: RequestOptions(path: '/demo'),
        type: DioExceptionType.connectionError,
      );
    }
    if (mode == 'empty') return [];
    return [
      RatingDto(
        ratingId: 3,
        movieId: 13,
        score: 3,
        comment: null,
        createdAt: DateTime.utc(2026, 10, 30),
      ),
      RatingDto(
        ratingId: 2,
        movieId: 680,
        score: 4,
        comment: '다시 봐도 좋다',
        createdAt: DateTime.utc(2026, 10, 29),
      ),
      RatingDto(
        ratingId: 1,
        movieId: 550,
        score: 5,
        comment: '최고의 영화!',
        createdAt: DateTime.utc(2026, 10, 28),
      ),
    ];
  }
}

class DemoMovieService extends TmdbMovieService {
  DemoMovieService() : super(Dio());

  @override
  Future<TmdbMovieDto> fetchMovie(
    int movieId, {
    CancelToken? cancelToken,
  }) async => TmdbMovieDto.fromJson({
    'id': movieId,
    'title': {13: '포레스트 검프', 680: '펄프 픽션', 550: '파이트 클럽'}[movieId] ?? '샘플 영화',
    'poster_path': null,
  });

  @override
  Future<TmdbMoviePageDto> fetchPopular({
    int page = 1,
    CancelToken? cancelToken,
  }) async => _page(page);

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    int page = 1,
    List<int>? genreIds,
    CancelToken? cancelToken,
  }) async => _page(page);

  Future<TmdbMoviePageDto> _page(int page) async => TmdbMoviePageDto(
    page: page,
    totalPages: 1,
    totalResults: 3,
    results: await Future.wait([13, 680, 550].map(fetchMovie)),
  );

  @override
  Future<List<TmdbGenreDto>> fetchGenres({CancelToken? cancelToken}) async =>
      const [];
}
