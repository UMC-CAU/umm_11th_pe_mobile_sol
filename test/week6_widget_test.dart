import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'support/movie_fakes.dart';
import 'support/week6_fakes.dart';

void phoneViewport(WidgetTester tester, {double width = 393}) {
  tester.view.physicalSize = Size(width, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

MovieLogApp testApp({
  String path = '/signup',
  FakeMemberCheckService? checks,
  FakeRatingApiService? ratings,
  FakeTmdbService? movies,
}) => MovieLogApp(
  initialLocation: path,
  memberCheckService: checks ?? FakeMemberCheckService(),
  ratingApiService: ratings ?? FakeRatingApiService(),
  movieService: movies ?? FakeTmdbService(),
  genrePreferences: MemoryGenrePreferences(),
);

ElevatedButton button(WidgetTester tester, String key) => tester.widget(
  find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(ElevatedButton),
  ),
);

void main() {
  testWidgets(
    'signup displays checking, duplicate, restored duplicate and available',
    (tester) async {
      phoneViewport(tester);
      final response = Completer<bool>();
      final checks = FakeMemberCheckService()
        ..onNickname = (_) => response.future;
      await tester.pumpWidget(testApp(checks: checks));
      await tester.pumpAndSettle();
      expect(button(tester, 'check-nickname').onPressed, isNull);
      await tester.enterText(find.byKey(const Key('signup-nickname')), '중복닉네임');
      await tester.pump();
      await tester.tap(find.byKey(const Key('check-nickname')));
      await tester.pump();
      expect(button(tester, 'check-nickname').onPressed, isNull);
      expect(
        find.descendant(
          of: find.byKey(const Key('check-nickname')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('check-nickname')),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      response.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      final field = tester.widget<TextFormField>(
        find.byKey(const Key('signup-nickname')),
      );
      expect(field.forceErrorText, isNotNull);
      expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
      await tester.enterText(find.byKey(const Key('signup-nickname')), '새닉네임');
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
      expect(button(tester, 'check-nickname').onPressed, isNotNull);
      await tester.enterText(find.byKey(const Key('signup-nickname')), '중복닉네임');
      await tester.pumpAndSettle();
      expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
      expect(button(tester, 'check-nickname').onPressed, isNull);
      expect(checks.nicknames.length, 1);
      checks.onNickname = (_) => true;
      await tester.enterText(
        find.byKey(const Key('signup-nickname')),
        '사용가능닉네임',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('check-nickname')));
      await tester.pumpAndSettle();
      expect(find.text('사용할 수 있는 닉네임입니다.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('signup-nickname')), '다른닉네임');
      await tester.pumpAndSettle();
      expect(find.text('사용할 수 있는 닉네임입니다.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'submit needs both checks and moves home without creating an account',
    (tester) async {
      phoneViewport(tester);
      final checks = FakeMemberCheckService();
      await tester.pumpWidget(testApp(checks: checks));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('signup-nickname')), '한솔');
      await tester.enterText(
        find.byKey(const Key('signup-email')),
        'sol@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('signup-password')),
        'password123',
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(button(tester, 'signup-submit').onPressed, isNull);
      for (final key in ['check-nickname', 'check-email']) {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
      }
      expect(button(tester, 'signup-submit').onPressed, isNotNull);
      await tester.ensureVisible(find.byKey(const Key('signup-submit')));
      await tester.tap(find.byKey(const Key('signup-submit')));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(checks.nicknames, ['한솔']);
      expect(checks.emails, ['sol@example.com']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '320px signup remains scrollable with keyboard and server errors',
    (tester) async {
      phoneViewport(tester, width: 320);
      final checks = FakeMemberCheckService()
        ..onEmail = (_) => throw testHttpError();
      await tester.pumpWidget(testApp(checks: checks));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('signup-email')),
        'sol@example.com',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('check-email')));
      await tester.tap(find.byKey(const Key('check-email')));
      await tester.pumpAndSettle();
      expect(find.text('중복 확인에 실패했습니다. 다시 시도해 주세요.'), findsOneWidget);
      expect(button(tester, 'check-email').onPressed, isNotNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('signup-submit')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'profile pushes ratings above tabs and back restores the profile',
    (tester) async {
      phoneViewport(tester);
      final ratings = FakeRatingApiService();
      await tester.pumpWidget(testApp(path: '/my', ratings: ratings));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.ensureVisible(find.text('내가 등록한 평점'));
      await tester.tap(find.text('내가 등록한 평점'));
      await tester.pumpAndSettle();
      expect(find.byType(MyRatingsScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('학습용 회원 #1의 공개 평점입니다.'), findsOneWidget);
      expect(ratings.memberIds, [1]);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('내 프로필'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ratings shows loading, error, retry, empty and success', (
    tester,
  ) async {
    phoneViewport(tester);
    final response = Completer<List<RatingDto>>();
    final ratings = FakeRatingApiService()..onFetch = (_) => response.future;
    final movies = FakeTmdbService()
      ..onDetail = (_) => throw testHttpError(status: 404);
    await tester.pumpWidget(
      testApp(path: '/my/ratings', ratings: ratings, movies: movies),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.completeError(testHttpError(status: 404));
    await tester.pumpAndSettle();
    expect(find.text('존재하지 않는 회원입니다.'), findsOneWidget);
    ratings.onFetch = (_) => [];
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('등록된 평점이 없어요.'), findsOneWidget);
    ratings.onFetch = (_) => [testRating(comment: null)];
    await tester.tap(find.text('새로고침'));
    await tester.pumpAndSettle();
    expect(find.text('영화 정보 없음'), findsOneWidget);
    expect(find.text('TMDB ID 550'), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget);
    expect(find.text('null'), findsNothing);
    expect(find.text('수정'), findsNothing);
    expect(find.text('삭제'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'button width null, infinity and fixed override app minimum width',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MovieLogButton(
                      key: const Key('intrinsic'),
                      label: '확인',
                      onPressed: () {},
                    ),
                    MovieLogButton(
                      key: const Key('full'),
                      label: '확인',
                      width: double.infinity,
                      onPressed: () {},
                    ),
                    MovieLogButton(
                      key: const Key('fixed'),
                      label: '확인',
                      width: 96,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('intrinsic'))).width,
        lessThan(300),
      );
      expect(tester.getSize(find.byKey(const Key('full'))).width, 300);
      expect(tester.getSize(find.byKey(const Key('fixed'))).width, 96);
      expect(tester.takeException(), isNull);
    },
  );
}
