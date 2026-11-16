// Optional UI evidence capture with an external Korean font (not a device recording).
// flutter test tool/capture_week6_test.dart --dart-define=CAPTURE_FONT=/absolute/font.ttf
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/models/rating_dto.dart';

import '../test/support/movie_fakes.dart';
import '../test/support/week6_fakes.dart';
import 'week6_buttons.dart';

const boundaryKey = Key('capture-boundary');

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/evidence/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Widget labeled(Widget child) => RepaintBoundary(
  key: boundaryKey,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: IgnorePointer(
            child: ColoredBox(
              color: const Color(0xCCB71C1C),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  'DEMO DATA',
                  style: TextStyle(
                    inherit: false,
                    fontFamily: 'Manrope',
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);

void main() {
  const fontPath = String.fromEnvironment('CAPTURE_FONT');
  setUpAll(() async {
    if (fontPath.isEmpty) return;
    final bytes = Uint8List.fromList(await File(fontPath).readAsBytes());
    for (final family in ['Manrope', 'Roboto']) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets(
    'render week 6 UI evidence with deterministic service responses',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pendingNickname = Completer<bool>();
      final checks = FakeMemberCheckService()
        ..onNickname = (_) => pendingNickname.future;
      await tester.pumpWidget(
        labeled(
          MovieLogApp(
            key: UniqueKey(),
            initialLocation: '/signup',
            memberCheckService: checks,
            movieService: FakeTmdbService(),
            genrePreferences: MemoryGenrePreferences(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, '01-signup-idle');
      await tester.enterText(find.byKey(const Key('signup-nickname')), '중복닉네임');
      await tester.pump();
      await tester.tap(find.byKey(const Key('check-nickname')));
      await tester.pump(const Duration(milliseconds: 300));
      await capture(tester, '02-signup-checking');
      pendingNickname.complete(false);
      await tester.pumpAndSettle();
      await capture(tester, '03-signup-duplicated');
      checks.onNickname = (_) => true;
      await tester.enterText(
        find.byKey(const Key('signup-nickname')),
        '새로운닉네임',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('check-nickname')));
      await tester.pumpAndSettle();
      await capture(tester, '04-signup-available');

      final pendingRatings = Completer<List<RatingDto>>();
      final ratings = FakeRatingApiService()
        ..onFetch = (_) => pendingRatings.future;
      await tester.pumpWidget(
        labeled(
          MovieLogApp(
            key: UniqueKey(),
            initialLocation: '/my/ratings',
            ratingApiService: ratings,
            movieService: FakeTmdbService(),
            genrePreferences: MemoryGenrePreferences(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await capture(tester, '05-ratings-loading');
      pendingRatings.completeError(testHttpError());
      await tester.pumpAndSettle();
      await capture(tester, '06-ratings-error');
      ratings.onFetch = (_) => [];
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      await capture(tester, '07-ratings-empty');
      ratings.onFetch = (_) => [
        testRating(comment: '최고의 영화!'),
        testRating(id: 2, movieId: 13),
      ];
      await tester.tap(find.text('새로고침'));
      await tester.pumpAndSettle();
      await capture(tester, '08-ratings-success');
      await tester.pumpWidget(labeled(const ButtonPreviewApp()));
      await tester.pump(const Duration(milliseconds: 300));
      await capture(tester, '09-button-widths');
      expect(tester.takeException(), isNull);
    },
    skip: fontPath.isEmpty,
  );
}
