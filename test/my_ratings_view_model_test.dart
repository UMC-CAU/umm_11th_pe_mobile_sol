import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'support/movie_fakes.dart';
import 'support/week6_fakes.dart';

void main() {
  test('empty array transitions loading to empty with member 1', () async {
    final response = Completer<List<RatingDto>>();
    final service = FakeRatingApiService()..onFetch = (_) => response.future;
    final movies = FakeTmdbService();
    final vm = MyRatingsViewModel(service, movies, 1);
    addTearDown(vm.dispose);
    final pending = vm.load();
    expect(vm.status, MyRatingsLoadStatus.loading);
    response.complete([]);
    await pending;
    expect(vm.status, MyRatingsLoadStatus.empty);
    expect(service.memberIds, [1]);
    expect(movies.detailIds, isEmpty);
  });

  test(
    'movie details are cached without changing backend rating order',
    () async {
      final service = FakeRatingApiService()
        ..onFetch = (_) => [
          testRating(id: 3, movieId: 13),
          testRating(id: 2, movieId: 550, comment: '최고의 영화!'),
          testRating(id: 1, movieId: 550),
        ];
      final movies = FakeTmdbService();
      final vm = MyRatingsViewModel(service, movies, 1);
      addTearDown(vm.dispose);
      await vm.load();
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.success);
      expect(vm.ratings.map((entry) => entry.rating.ratingId), [3, 2, 1]);
      expect(vm.ratings.last.rating.comment, isNull);
      expect(vm.ratings.first.movie!.title, '영화 13');
      expect(movies.detailIds, [13, 550]);
    },
  );

  test('TMDB 404 is cached as missing while ratings stay visible', () async {
    final movies = FakeTmdbService()
      ..onDetail = (_) => throw testHttpError(status: 404);
    final vm = MyRatingsViewModel(FakeRatingApiService(), movies, 1);
    addTearDown(vm.dispose);
    await vm.load();
    await vm.load();
    expect(vm.status, MyRatingsLoadStatus.success);
    expect(vm.ratings.single.rating.movieId, 550);
    expect(vm.ratings.single.movie, isNull);
    expect(vm.message, contains('일부 영화 정보'));
    expect(movies.detailIds, [550]);
  });

  test(
    'temporary TMDB failure is attempted once per ID and retries next load',
    () async {
      final service = FakeRatingApiService()
        ..onFetch = (_) => [testRating(id: 2), testRating(id: 1)];
      final movies = FakeTmdbService()..onDetail = (_) => throw testHttpError();
      final vm = MyRatingsViewModel(service, movies, 1);
      addTearDown(vm.dispose);
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.success);
      expect(vm.ratings.length, 2);
      expect(movies.detailIds, [550]);
      movies.onDetail = testMovie;
      await vm.load();
      expect(movies.detailIds, [550, 550]);
      expect(vm.ratings.every((entry) => entry.movie != null), isTrue);
      expect(vm.message, isNull);
    },
  );

  for (final status in [400, 404, 500]) {
    test('backend HTTP $status is an error rather than empty', () async {
      final service = FakeRatingApiService()
        ..onFetch = (_) => throw testHttpError(status: status);
      final vm = MyRatingsViewModel(service, FakeTmdbService(), 1);
      addTearDown(vm.dispose);
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.error);
      expect(
        vm.message,
        contains(switch (status) {
          400 => 'memberId',
          404 => '존재하지 않는 회원',
          _ => '잠시 후',
        }),
      );
      service.onFetch = (_) => [];
      await vm.load();
      expect(vm.status, MyRatingsLoadStatus.empty);
    });
  }

  test('newer load wins while an older detail response is pending', () async {
    final detail = Completer<TmdbMovieDto>();
    final started = Completer<void>();
    final service = FakeRatingApiService();
    final movies = FakeTmdbService()
      ..onDetail = (_) {
        started.complete();
        return detail.future;
      };
    final vm = MyRatingsViewModel(service, movies, 1);
    addTearDown(vm.dispose);
    final old = vm.load();
    await started.future;
    service.onFetch = (_) => [];
    await vm.load();
    detail.complete(testMovie(550));
    await old;
    expect(vm.status, MyRatingsLoadStatus.empty);
    expect(vm.ratings, isEmpty);
  });

  test('disposed screen ignores a late rating response', () async {
    final response = Completer<List<RatingDto>>();
    final service = FakeRatingApiService()..onFetch = (_) => response.future;
    final movies = FakeTmdbService();
    final vm = MyRatingsViewModel(service, movies, 1);
    var notifications = 0;
    vm.addListener(() => notifications++);
    final pending = vm.load();
    vm.dispose();
    response.complete([testRating()]);
    await pending;
    expect(notifications, 1);
    expect(movies.detailIds, isEmpty);
  });
}
