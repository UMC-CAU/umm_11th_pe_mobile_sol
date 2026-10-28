import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/movie_card.dart';
import 'package:movielog/data/models/movie_rating_draft.dart';
import 'package:movielog/movie_poster.dart';
import 'package:movielog/movie_rating_input.dart';
import 'package:movielog/movies_screen.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:provider/provider.dart';

import 'support/movie_fakes.dart';

void phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'original entry remains available without starting movie requests',
    (tester) async {
      phoneViewport(tester);
      final service = FakeTmdbService();
      await tester.pumpWidget(
        MovieLogApp(
          movieService: service,
          genrePreferences: MemoryGenrePreferences(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('시작하기'), findsOneWidget);
      expect(service.popularCalls, 0);
      expect(service.requests, isEmpty);
      await tester.ensureVisible(find.text('시작하기'));
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      expect(find.text('로그인'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'list loads once, shows real IDs and keeps search/sort controls',
    (tester) async {
      phoneViewport(tester);
      final service = FakeTmdbService();
      await tester.pumpWidget(
        MovieLogApp(
          initialLocation: '/movies',
          movieService: service,
          genrePreferences: MemoryGenrePreferences(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('영화 2편'), findsOneWidget);
      expect(find.text('영화 101'), findsOneWidget);
      expect(service.genreCalls, 1);
      expect(service.requests.length, 1);
      await tester.pump();
      expect(service.requests.length, 1);
      await tester.tap(find.byTooltip('영화 검색'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '202');
      await tester.pumpAndSettle();
      expect(find.text('영화 101'), findsNothing);
      expect(find.text('영화 202'), findsOneWidget);
      expect(service.requests.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading disables genre selection and pull to refresh duplication',
    (tester) async {
      phoneViewport(tester);
      final pending = Completer<TmdbMoviePageDto>();
      final service = FakeTmdbService()
        ..onDiscover = (page, ids) => pending.future;
      await tester.pumpWidget(
        MovieLogApp(
          initialLocation: '/movies',
          movieService: service,
          genrePreferences: MemoryGenrePreferences(),
        ),
      );
      await tester.pump();
      for (final chip in tester.widgetList<ChoiceChip>(
        find.byType(ChoiceChip),
      )) {
        expect(chip.onSelected, isNull);
      }
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump();
      expect(service.requests.length, 1);
      pending.complete(testPage([55]));
      await tester.pumpAndSettle();
      expect(find.text('영화 55'), findsOneWidget);
    },
  );

  testWidgets(
    'genre sheet confirms multi selection and cancel sends no request',
    (tester) async {
      phoneViewport(tester);
      final service = FakeTmdbService();
      await tester.pumpWidget(
        MovieLogApp(
          initialLocation: '/movies',
          movieService: service,
          genrePreferences: MemoryGenrePreferences(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('장르 여러 개 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, '액션'));
      await tester.tap(find.widgetWithText(FilterChip, '드라마'));
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(service.requests.last.ids, [18, 28]);
      expect(service.requests.last.page, 1);
      final count = service.requests.length;
      await tester.tap(find.byTooltip('장르 여러 개 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, '전체'));
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(service.requests.length, count);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'refresh failure dialog retains list; cancel then retry succeeds',
    (tester) async {
      phoneViewport(tester);
      final service = FakeTmdbService();
      await tester.pumpWidget(
        MovieLogApp(
          initialLocation: '/movies',
          movieService: service,
          genrePreferences: MemoryGenrePreferences(ids: [28]),
        ),
      );
      await tester.pumpAndSettle();
      final vm = tester
          .element(find.byType(MoviesScreen))
          .read<MovieListViewModel>();
      service.onDiscover = (page, ids) =>
          throw StateError('Network unavailable');
      await vm.refresh();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('영화 101'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      service.onDiscover = (page, ids) => testPage([303]);
      await tester.tap(find.text('재시도'));
      await tester.pumpAndSettle();
      expect(service.requests.last.ids, [28]);
      expect(find.text('영화 303'), findsOneWidget);
      expect(find.text('영화 101'), findsNothing);
    },
  );

  testWidgets(
    'numeric deep link loads detail and gives its ID to rating dialog',
    (tester) async {
      phoneViewport(tester);
      final service = FakeTmdbService();
      await tester.pumpWidget(
        MovieLogApp(
          initialLocation: '/movies/98765',
          movieService: service,
          genrePreferences: MemoryGenrePreferences(),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.detailIds, [98765]);
      expect(find.text('영화 98765'), findsOneWidget);
      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      final dialog = tester.widget<MovieRatingInput>(
        find.byType(MovieRatingInput),
      );
      expect(dialog.movieId, 98765);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rating result contains TMDB ID and the five-point user score', (
    tester,
  ) async {
    MovieRatingDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<MovieRatingDraft>(
                  context: context,
                  builder: (_) =>
                      const MovieRatingInput(movieId: 4321, initialRating: 4),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(result!.movieId, 4321);
    expect(result!.score, 4);
  });

  testWidgets('missing poster is a visible placeholder', (tester) async {
    phoneViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 180,
          height: 270,
          child: TmdbPoster(posterPath: null),
        ),
      ),
    );
    expect(find.byType(MoviePosterPlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
  testWidgets('failed poster download uses the error placeholder', (
    tester,
  ) async {
    phoneViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 180,
          height: 270,
          child: TmdbPoster(posterPath: '/broken-poster-for-test.jpg'),
        ),
      ),
    );
    // Flutter's test HTTP client returns 400 without making a real HTTP request.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    final placeholder = tester.widget<MoviePosterPlaceholder>(
      find.byType(MoviePosterPlaceholder),
    );
    expect(placeholder.loading, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('null overview is centered with the workbook message', (
    tester,
  ) async {
    phoneViewport(tester);
    final service = FakeTmdbService()
      ..onDetail = (id) => TmdbMovieDto.fromJson({
        'id': id,
        'title': '빈 줄거리 영화',
        'overview': null,
        'poster_path': null,
        'release_date': null,
        'genre_ids': null,
      });
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/movies/2468',
        movieService: service,
        genrePreferences: MemoryGenrePreferences(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('줄거리 정보가 없어요.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final message = find.text('줄거리 정보가 없어요.');
    expect(message, findsOneWidget);
    expect(tester.getCenter(message).dx, closeTo(393 / 2, 1));
    expect(find.text('개봉일 미정'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card omits missing year without a leading separator', (
    tester,
  ) async {
    phoneViewport(tester);
    final movie = TmdbMovieDto.fromJson({
      'id': 2468,
      'title': '날짜 없는 영화',
      'release_date': null,
      'genre_ids': [28],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: MovieCard(movie: movie, genres: testGenres, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('액션'), findsOneWidget);
    expect(find.text(' · 액션'), findsNothing);
    expect(find.text('개봉일 미정'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('app exposes separate typed clients without shadowing TMDB', (
    tester,
  ) async {
    phoneViewport(tester);
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/movies',
        movieService: FakeTmdbService(),
        genrePreferences: MemoryGenrePreferences(),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(MoviesScreen));
    final tmdb = context.read<TmdbClient>();
    final movieLog = context.read<MovieLogClient>();
    expect(tmdb.dio, isNot(same(movieLog.dio)));
    expect(tmdb.dio.options.baseUrl, 'https://api.themoviedb.org/3');
    expect(movieLog.dio.options.headers.containsKey('Authorization'), isFalse);
    expect(find.text('영화 101'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
