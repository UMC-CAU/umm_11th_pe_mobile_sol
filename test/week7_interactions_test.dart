import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'support/movie_fakes.dart';
import 'support/week6_fakes.dart';
import 'week7_crud_test.dart' show httpError;

void main() {
  Future<void> openRatings(
    WidgetTester tester,
    FakeRatingApiService service,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = LearningMemberSession()..setMemberId(37);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/my/ratings',
        ratingApiService: service,
        movieService: FakeTmdbService(),
        genrePreferences: MemoryGenrePreferences(),
        learningMemberSession: session,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'delete cancel makes no request; pending delete cannot be dismissed',
    (tester) async {
      final pending = Completer<void>();
      final service = FakeRatingApiService();
      service.onFetch = (_) => [testRating(id: 12)];
      service.onDelete = (_, _) => pending.future;
      await openRatings(tester, service);
      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(service.deleted, isEmpty);
      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '삭제'));
      await tester.pump();
      expect(service.deleted, [12]);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('평점을 삭제할까요?'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      service.onFetch = (_) => <RatingDto>[];
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('평점을 삭제할까요?'), findsNothing);
      expect(find.text('등록된 평점이 없어요.'), findsOneWidget);
    },
  );

  testWidgets(
    'edit failure preserves input; successful write with failed GET only retries GET',
    (tester) async {
      var writes = 0;
      final service = FakeRatingApiService()
        ..onFetch = (_) => [testRating(id: 12, comment: '원래 후기')];
      service.onUpdate = (_, _, _, _) {
        writes++;
        throw httpError(403, '본인의 평점만 수정할 수 있습니다.');
      };
      await openRatings(tester, service);
      await tester.tap(find.byTooltip('수정'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('rating-comment')))
            .controller!
            .text,
        '원래 후기',
      );
      await tester.enterText(find.byKey(const Key('rating-comment')), '바꾼 후기');
      await tester.tap(find.byKey(const Key('rating-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('본인의 평점만 수정할 수 있습니다.'), findsOneWidget);
      expect(find.text('바꾼 후기'), findsOneWidget);
      service.onUpdate = (_, _, _, _) {
        writes++;
      };
      service.onFetch = (_) => throw httpError(500, '조회 실패');
      await tester.tap(find.byKey(const Key('rating-confirm')));
      await tester.pumpAndSettle();
      expect(
        find.text('저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.'),
        findsOneWidget,
      );
      service.onFetch = (_) => [];
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(writes, 2);
      expect(find.text('등록된 평점이 없어요.'), findsOneWidget);
    },
  );

  testWidgets(
    'multiple selection keeps failed rating selected after partial deletion',
    (tester) async {
      final service = FakeRatingApiService();
      service.onFetch = (_) => [
        testRating(id: 1),
        testRating(id: 2, movieId: 551),
      ];
      service.onDelete = (_, id) {
        if (id == 2) throw httpError(403, '권한 없음');
      };
      await openRatings(tester, service);
      await tester.tap(find.text('편집'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox).at(0));
      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();
      await tester.tap(find.text('선택한 2개 삭제'));
      await tester.pumpAndSettle();
      service.onFetch = (_) => [testRating(id: 2, movieId: 551)];
      await tester.tap(find.widgetWithText(TextButton, '삭제'));
      await tester.pumpAndSettle();
      expect(service.deleted, [1, 2]);
      expect(find.textContaining('1개 항목을 삭제하지 못했습니다'), findsOneWidget);
      expect(find.text('1개 선택됨'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    },
  );
}
