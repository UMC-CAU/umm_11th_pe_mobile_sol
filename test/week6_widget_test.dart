import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'support/movie_fakes.dart';
import 'support/week6_fakes.dart';
import 'support/week8_fakes.dart';

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
  bool member = false,
}) => MovieLogApp(
  initialLocation: path,
  authViewModel: testAuth(signedIn: member),
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

  testWidgets('submit needs both checks and creates an account', (
    tester,
  ) async {
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
      'Password1!',
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
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(checks.nicknames, ['한솔']);
    expect(checks.emails, ['sol@example.com']);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('profile opens current session ratings and back returns', (tester) async {
    phoneViewport(tester); await tester.pumpWidget(testApp(path: '/my', member: true)); await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('이번 세션의 평점')); await tester.pumpAndSettle();
    expect(find.byType(MyRatingsScreen), findsOneWidget); expect(find.text('이번 세션에 등록한 평점이 없어요.'), findsOneWidget);
    await tester.tap(find.byType(BackButton)); await tester.pumpAndSettle(); expect(find.text('내 프로필'), findsOneWidget);
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
