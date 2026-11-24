import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/movie_request_state.dart';
import 'package:movielog/view_models/load_phase.dart';

import 'support/movie_fakes.dart';

void main() {
  test(
    'popular safely uses at most five, including a shorter response',
    () async {
      final service = FakeTmdbService();
      final vm = MovieHomeViewModel(service);
      await vm.load();
      expect(vm.movies.length, 5);
      service.onPopular = () => testPage([9, 10]);
      await vm.load();
      expect(vm.movies.map((movie) => movie.id), [9, 10]);
      expect(vm.status, MovieLoadStatus.success);
      vm.dispose();
    },
  );

  test('popular empty/error/retry transitions', () async {
    final service = FakeTmdbService()..onPopular = () => testPage([]);
    final vm = MovieHomeViewModel(service);
    await vm.load();
    expect(vm.status, MovieLoadStatus.empty);
    service.onPopular = () => throw StateError('Offline');
    await vm.load();
    expect(vm.status, MovieLoadStatus.error);
    service.onPopular = () => testPage([42]);
    await vm.load();
    expect(vm.status, MovieLoadStatus.success);
    expect(vm.errorMessage, isNull);
    vm.dispose();
  });

  test(
    'first page loads independently and pagination deduplicates beyond thirty',
    () async {
      final service = FakeTmdbService()
        ..onDiscover = (page, ids) => switch (page) {
          1 => testPage(List.generate(12, (i) => i + 1), totalPages: 5),
          2 => testPage(
            List.generate(15, (i) => i + 10),
            page: 2,
            totalPages: 5,
          ),
          _ => testPage(
            List.generate(17, (i) => i + 24),
            page: page,
            totalPages: 5,
          ),
        };
      final vm = MovieListViewModel(service, MemoryGenrePreferences());
      await vm.load();
      expect(service.requests.map((request) => request.page), [1]);
      expect(vm.movies.length, 12);
      await vm.loadNextPage();
      await vm.loadNextPage();
      expect(service.requests.map((request) => request.page), [1, 2, 3]);
      expect(
        vm.movies.map((movie) => movie.id),
        List.generate(40, (i) => i + 1),
      );
      vm.dispose();
    },
  );

  test('last page and an empty first page both stop pagination', () async {
    final service = FakeTmdbService()
      ..onDiscover = (page, ids) => testPage([1, 2, 3]);
    final vm = MovieListViewModel(service, MemoryGenrePreferences());
    await vm.load();
    expect(vm.phase, LoadPhase.ready);
    expect(vm.movies.length, 3);
    expect(vm.hasMore, isFalse);
    service.onDiscover = (page, ids) => testPage([], totalPages: 100);
    await vm.refresh();
    expect(vm.phase, LoadPhase.empty);
    expect(service.requests.length, 2);
    vm.dispose();
  });

  test(
    'restore valid IDs; selecting genres starts from page one and does not locally filter',
    () async {
      final service = FakeTmdbService();
      final preferences = MemoryGenrePreferences(ids: [18, 999]);
      final vm = MovieListViewModel(service, preferences);
      await vm.load();
      expect(vm.selectedGenreIds, [18]);
      expect(service.requests.single.ids, [18]);
      expect(
        vm.movies.length,
        2,
      ); // Fixture has action IDs: no local genre filtering.
      await vm.selectGenres([28, 18, 28]);
      expect(vm.selectedGenreIds, [18, 28]);
      expect(service.requests.last.page, 1);
      expect(service.requests.last.ids, [18, 28]);
      await vm.selectGenres([]);
      expect(service.requests.last.ids, isNull);
      expect(preferences.ids, isEmpty);
      vm.dispose();
    },
  );

  test('explicit URL genres take precedence over stored selection', () async {
    final vm = MovieListViewModel(
      FakeTmdbService(),
      MemoryGenrePreferences(ids: [18]),
      initialGenreIds: [],
    );
    await vm.load();
    expect(vm.selectedGenreIds, isEmpty);
    vm.dispose();
  });

  test('a new genre supersedes a pending refresh', () async {
    final service = FakeTmdbService();
    final vm = MovieListViewModel(service, MemoryGenrePreferences());
    addTearDown(vm.dispose);
    await vm.load();
    final pending = Completer<TmdbMoviePageDto>();
    service.onDiscover = (page, ids) =>
        ids == null ? pending.future : testPage([303]);
    final refresh = vm.refresh();
    final oldToken = service.lastCancelToken!;
    expect(vm.phase, LoadPhase.loading);
    expect(vm.canSelectGenres, isTrue);
    expect(vm.movies, isEmpty);
    await vm.refresh();
    expect(service.requests.length, 2);
    await vm.selectGenres([28]);
    expect(oldToken.isCancelled, isTrue);
    expect(service.requests.length, 3);
    pending.complete(testPage([999]));
    await refresh;
    expect(vm.movies.single.id, 303);
    expect(vm.phase, LoadPhase.ready);
  });

  test(
    'page two failure keeps page one and retries page two with the same genres',
    () async {
      final service = FakeTmdbService();
      final vm = MovieListViewModel(service, MemoryGenrePreferences());
      addTearDown(vm.dispose);
      await vm.load();
      var shouldFail = true;
      service.onDiscover = (page, ids) {
        if (page == 2 && shouldFail) throw StateError('Offline on page two');
        return testPage(
          page == 1 ? [1, 2] : [2, 3, 4],
          page: page,
          totalPages: 2,
        );
      };
      await vm.selectGenres([28]);
      await vm.loadNextPage();
      expect(vm.phase, LoadPhase.ready);
      expect(vm.movies.map((movie) => movie.id), [1, 2]);
      expect(vm.loadMoreError, isNotNull);
      shouldFail = false;
      await vm.loadNextPage();
      expect(service.requests.map((request) => request.page), [1, 1, 2, 2]);
      expect(service.requests.last.ids, [28]);
      expect(vm.movies.map((movie) => movie.id), [1, 2, 3, 4]);
      expect(vm.hasMore, isFalse);
      expect(vm.loadMoreError, isNull);
    },
  );

  test('storage failure does not block movie requests', () async {
    final vm = MovieListViewModel(
      FakeTmdbService(),
      MemoryGenrePreferences(failRead: true, failWrite: true),
    );
    await vm.load();
    expect(vm.phase, LoadPhase.ready);
    expect(vm.preferenceMessage, isNotNull);
    await vm.selectGenres([28]);
    expect(vm.phase, LoadPhase.ready);
    await Future<void>.delayed(Duration.zero);
    expect(vm.preferenceMessage, contains('저장하지 못했어요'));
    vm.dispose();
  });

  test(
    'late response after disposal is cancelled and never notifies',
    () async {
      final pending = Completer<TmdbMoviePageDto>();
      final service = FakeTmdbService()
        ..onDiscover = (page, ids) => pending.future;
      final vm = MovieListViewModel(service, MemoryGenrePreferences());
      var notifications = 0;
      vm.addListener(() => notifications++);
      final load = vm.load();
      await Future<void>.delayed(Duration.zero);
      vm.dispose();
      final before = notifications;
      expect(service.lastCancelToken!.isCancelled, isTrue);
      pending.complete(testPage([999]));
      await load;
      expect(notifications, before);
      expect(vm.movies, isEmpty);
    },
  );

  test(
    'detail can reload from numeric path without extra; invalid path never calls API',
    () async {
      final service = FakeTmdbService();
      final vm = MovieDetailViewModel(
        service,
        movieId: 901,
        initialMovie: testMovie(101),
      );
      expect(vm.movie, isNull);
      await vm.load();
      expect(vm.movie!.id, 901);
      expect(service.detailIds, [901]);
      vm.dispose();
      final invalid = MovieDetailViewModel(service, movieId: null);
      await invalid.load();
      expect(invalid.status, MovieLoadStatus.error);
      expect(service.detailIds, [901]);
      invalid.dispose();
    },
  );
}
