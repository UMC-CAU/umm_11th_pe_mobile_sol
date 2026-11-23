import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

import 'support/movie_fakes.dart';
import 'support/week8_fakes.dart';

void main() {
  test(
    'an older page two error does not update the new query or its footer',
    () async {
      final vm = PagedMoviesViewModel();
      addTearDown(vm.dispose);
      final oldPage = Completer<TmdbMoviePageDto>();
      await vm.loadInitial(
        (page, _) async =>
            page == 1 ? testPage([1], totalPages: 2) : oldPage.future,
      );
      final pending = vm.loadNextPage();
      expect(vm.isLoadingMore, isTrue);

      await vm.loadInitial((page, _) async => testPage([7], page: page));
      oldPage.completeError(StateError('Old query failed.'));
      await pending;

      expect(vm.movies.map((movie) => movie.id), [7]);
      expect(vm.isLoadingMore, isFalse);
      expect(vm.loadMoreError, isNull);
      expect(vm.hasMore, isFalse);
    },
  );

  test('the TMDB page limit is 500', () async {
    final vm = PagedMoviesViewModel();
    addTearDown(vm.dispose);
    final requested = <int>[];
    await vm.loadInitial((page, _) async {
      requested.add(page);
      return testPage([1], page: page, totalPages: 1200);
    });
    for (var i = 2; i <= 501; i++) {
      await vm.loadNextPage();
    }
    expect(requested, List.generate(500, (i) => i + 1));
    expect(vm.movies.single.id, 1);
    expect(vm.hasMore, isFalse);
  });

  testWidgets('load-more footer preserves cards and retries the same page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = testAuth();
    addTearDown(auth.dispose);
    final pending = Completer<TmdbMoviePageDto>();
    var attempts = 0;
    final service = FakeTmdbService()
      ..onDiscover = (page, _) {
        if (page == 1) return testPage([101, 202], totalPages: 2);
        return ++attempts == 1
            ? pending.future
            : testPage([202, 303], page: 2, totalPages: 2);
      };
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/movies',
        movieService: service,
        genrePreferences: MemoryGenrePreferences(),
        authViewModel: auth,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('더 보기'));
    await tester.pump();
    expect(find.text('영화 101'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.completeError(StateError('Next page unavailable.'));
    await tester.pumpAndSettle();
    expect(find.text('영화 101'), findsOneWidget);
    await tester.tap(find.text('다음 페이지 다시 시도'));
    await tester.pumpAndSettle();
    expect(service.requests.map((request) => request.page), [1, 2, 2]);
    expect(find.text('영화 3편'), findsOneWidget);
    expect(find.text('더 보기'), findsNothing);
  });

  testWidgets(
    'search distinguishes idle, empty and error and ignores an older query',
    (tester) async {
      final auth = testAuth();
      addTearDown(auth.dispose);
      final slow = Completer<TmdbMoviePageDto>();
      final service = FakeTmdbService()
        ..onSearch = (query, page) => switch (query) {
          'slow' => slow.future,
          'empty' => testPage([]),
          'error' => throw StateError('Search unavailable.'),
          _ => testPage([9]),
        };
      await tester.pumpWidget(
        MovieLogApp(
          initialLocation: '/movies/search',
          movieService: service,
          genrePreferences: MemoryGenrePreferences(),
          authViewModel: auth,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('검색어를 입력해 주세요.'), findsOneWidget);

      Future<void> submit(String text) async {
        await tester.enterText(find.byType(TextField), text);
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pump();
      }

      await submit('   ');
      expect(service.searchRequests, isEmpty);
      await submit('empty');
      await tester.pumpAndSettle();
      expect(find.text('검색 결과가 없어요.'), findsOneWidget);
      await submit('error');
      await tester.pumpAndSettle();
      expect(find.text('다시 시도'), findsOneWidget);
      await submit('slow');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await submit('new');
      slow.complete(testPage([1]));
      await tester.pumpAndSettle();
      expect(find.text('영화 9'), findsOneWidget);
      expect(find.text('영화 1'), findsNothing);
      expect(service.searchRequests.map((request) => request.page), [
        1,
        1,
        1,
        1,
      ]);
    },
  );
}
