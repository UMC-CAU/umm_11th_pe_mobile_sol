import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/movie_rating_input.dart';
import 'package:movielog/view_models/session_ratings.dart';
import 'package:provider/provider.dart';
import 'support/movie_fakes.dart';
import 'support/week6_fakes.dart';
import 'support/week8_fakes.dart';

void main() {
  testWidgets(
    'session rating is edited and removed without a memberId lookup',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = testAuth();
      final service = FakeRatingApiService();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        MovieLogApp(
          initialLocation: '/my/ratings',
          authViewModel: auth,
          ratingApiService: service,
          movieService: FakeTmdbService(),
          genrePreferences: MemoryGenrePreferences(),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(MyRatingsScreen));
      context.read<SessionRatings>().add(
        testRating(id: 12, comment: '원래 후기'),
        null,
        auth.sessionVersion,
      );
      await tester.pump();
      expect(find.text('영화 #550'), findsOneWidget);
      await tester.tap(find.byTooltip('수정'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(RatingDialog),
          matching: find.text('원래 후기'),
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const Key('rating-comment')), '새 후기');
      await tester.tap(find.byKey(const Key('rating-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('새 후기'), findsOneWidget);
      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '삭제'));
      await tester.pumpAndSettle();
      expect(find.text('이번 세션에 등록한 평점이 없어요.'), findsOneWidget);
      expect(service.memberIds, isEmpty);
    },
  );
  testWidgets('logout redirects a protected page to login', (tester) async {
    final auth = testAuth();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/my',
        authViewModel: auth,
        movieService: FakeTmdbService(),
        genrePreferences: MemoryGenrePreferences(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-email')), findsOneWidget);
  });
}
