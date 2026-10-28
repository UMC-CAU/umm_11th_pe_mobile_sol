import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie_poster.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/movies_screen.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/movie_request_state.dart';
import 'package:provider/provider.dart';

import 'support/movie_fakes.dart';

void main() {
  testWidgets(
    'null mode ignores an available API poster and shows the missing placeholder',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 180,
            height: 270,
            child: TmdbPoster(
              posterPath: '/available-api-poster.jpg',
              debugMode: PosterDebugMode.missing,
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsNothing);
      expect(
        tester
            .widget<MoviePosterPlaceholder>(find.byType(MoviePosterPlaceholder))
            .loading,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'error mode uses a broken image request and then the failure placeholder',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 180,
            height: 270,
            child: TmdbPoster(
              posterPath: '/available-api-poster.jpg',
              debugMode: PosterDebugMode.failure,
            ),
          ),
        ),
      );
      final provider =
          tester.widget<Image>(find.byType(Image)).image as NetworkImage;
      expect(
        provider.url,
        isNot(TmdbPoster.imageUrl('/available-api-poster.jpg')),
      );
      expect(Uri.parse(provider.url).host, 'image.tmdb.org');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MoviePosterPlaceholder>(find.byType(MoviePosterPlaceholder))
            .loading,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dart-define chooses normal, null or error mode for movie posters',
    (tester) async {
      const setting = String.fromEnvironment(
        'POSTER_TEST_MODE',
        defaultValue: 'normal',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 180,
            height: 270,
            child: TmdbPoster(posterPath: '/available-api-poster.jpg'),
          ),
        ),
      );
      if (setting == 'null') {
        expect(find.byType(Image), findsNothing);
        expect(find.byType(MoviePosterPlaceholder), findsOneWidget);
      } else {
        final provider =
            tester.widget<Image>(find.byType(Image)).image as NetworkImage;
        if (setting == 'error') {
          expect(
            provider.url,
            isNot(TmdbPoster.imageUrl('/available-api-poster.jpg')),
          );
        } else {
          expect(
            provider.url,
            TmdbPoster.imageUrl('/available-api-poster.jpg'),
          );
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('poster preview keeps a successful movie list and count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/movies',
        movieService: FakeTmdbService(),
        genrePreferences: MemoryGenrePreferences(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    final vm = tester
        .element(find.byType(MoviesScreen))
        .read<MovieListViewModel>();
    expect(vm.status, MovieLoadStatus.success);
    expect(vm.movies.length, 2);
    expect(find.text('영화 2편'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(MoviePosterPlaceholder), findsWidgets);
    for (final placeholder in tester.widgetList<MoviePosterPlaceholder>(
      find.byType(MoviePosterPlaceholder),
    )) {
      expect(placeholder.loading, isFalse);
    }
    expect(tester.takeException(), isNull);
  });
}
