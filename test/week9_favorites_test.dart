import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';

import 'support/capturing_adapter.dart';
import 'support/favorite_fixture.dart';
import 'support/movie_fakes.dart';
import 'support/week8_fakes.dart';

void main() {
  test('favorite service uses v8 wrappers and the TMDB movie ID', () async {
    final adapter = CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
      ..httpClientAdapter = adapter;
    addTearDown(dio.close);
    final service = FavoriteApiService(dio);
    const favorite = {
      'favoriteId': 12,
      'movieId': 550,
      'createdAt': '2026-11-20T00:00:00Z',
    };

    adapter.body = _response([favorite]);
    expect((await service.fetchMyFavorites()).single.favoriteId, 12);
    expect(adapter.requests.single.queryParameters, isEmpty);

    adapter.body = _response({'isFavorite': true});
    final status = await service.getStatus(550);
    expect(status.movieId, 550);
    expect(status.isFavorite, isTrue);

    adapter.status = 201;
    adapter.body = _response(favorite);
    expect((await service.add(550)).movieId, 550);
    expect(adapter.requests.last.data, {'movieId': 550});

    adapter.status = 200;
    adapter.body = _response(null);
    await service.remove(550);
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /v8/favorites',
        'GET /v8/favorites/550',
        'POST /v8/favorites',
        'DELETE /v8/favorites/550',
      ],
    );
    adapter.body = _response([]);
    expect(await service.fetchMyFavorites(), isEmpty);
  });

  test('duplicate and missing favorites reconcile with the server', () async {
    final api = FavoriteFixture({550});
    final session = SessionGuard()..replaceAccount('a');
    final vm = FavoriteDetailViewModel(
      api: api,
      session: session,
      accountId: 'a',
      movieId: 550,
    );
    addTearDown(vm.dispose);
    await vm.load();

    api.ids.clear();
    api.beforeRemove = (_) => throw _httpError(404, 'FAVORITE404_1');
    expect(await vm.toggle(), contains('등록되어 있지'));
    expect(vm.isFavorite, isFalse);

    api.ids.add(550);
    api.beforeAdd = (_) => throw _httpError(409, 'FAVORITE409_1');
    expect(await vm.toggle(), contains('이미'));
    expect(vm.isFavorite, isTrue);
    expect(api.statusReads, [550, 550, 550]);
    expect(api.removals, [550]);
    expect(api.additions, [550]);

    api.beforeRemove = (_) => throw _httpError(404, 'MEMBER404_1');
    expect(await vm.toggle(), contains('회원 정보'));
    expect(vm.isFavorite, isTrue);
    expect(api.statusReads, [550, 550, 550]);
  });

  test(
    'a lost write response keeps the bookmark until explicit retry confirms it',
    () async {
      final api = FavoriteFixture({});
      final session = SessionGuard()..replaceAccount('a');
      final vm = FavoriteDetailViewModel(
        api: api,
        session: session,
        accountId: 'a',
        movieId: 550,
      );
      addTearDown(vm.dispose);
      await vm.load();
      final pending = Completer<void>();
      api.beforeAdd = (_) => pending.future;

      final save = vm.toggle();
      expect(vm.isSaving, isTrue);
      expect(await vm.toggle(), isNull);
      expect(vm.isFavorite, isFalse);

      api.ids.add(550);
      pending.completeError(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.receiveTimeout,
        ),
      );
      expect(await save, contains('실패'));
      expect(vm.isFavorite, isFalse);
      expect(await vm.toggle(), contains('이미'));
      expect(vm.isFavorite, isTrue);
      expect(api.additions, [550]);
      expect(api.statusReads, [550, 550]);
    },
  );

  test(
    'favorites enrichment caps concurrency and retries the affected card',
    () async {
      final api = FavoriteFixture(Set.from(List.generate(12, (i) => i + 1)));
      final session = SessionGuard()..replaceAccount('a');
      var active = 0;
      var peak = 0;
      final movieApi = FakeTmdbService()
        ..onDetail = (id) async {
          active++;
          peak = max(peak, active);
          await Future<void>.delayed(Duration.zero);
          active--;
          if (id == 3) throw StateError('TMDB detail failed.');
          return testMovie(id);
        };
      final vm = FavoritesViewModel(
        favoriteApi: api,
        tmdbApi: movieApi,
        session: session,
        accountId: 'a',
      );
      addTearDown(vm.dispose);
      await vm.refresh();
      expect(peak, 5);
      expect(vm.phase, LoadPhase.ready);
      expect(
        vm.items.where((item) => item.movie == null).single.favorite.movieId,
        3,
      );

      movieApi.detailIds.clear();
      movieApi.onDetail = testMovie;
      await vm.retryMovie(3);
      expect(movieApi.detailIds, [3]);
      expect(
        vm.items.map((item) => item.movie?.id),
        List.generate(12, (i) => i + 1),
      );

      api.readList = () => throw StateError('Favorite list failed.');
      await vm.refresh();
      expect(vm.phase, LoadPhase.error);
      api.readList = () => [];
      await vm.refresh();
      expect(vm.phase, LoadPhase.empty);
    },
  );

  test(
    'a late response is discarded even after signing back into the same account',
    () async {
      final pending = Completer<List<FavoriteResponseDto>>();
      final api = FavoriteFixture({550})..readList = () => pending.future;
      final session = SessionGuard()..replaceAccount('a');
      final movies = FakeTmdbService();
      final vm = FavoritesViewModel(
        favoriteApi: api,
        tmdbApi: movies,
        session: session,
        accountId: 'a',
      );
      addTearDown(vm.dispose);
      final refresh = vm.refresh();
      session.replaceAccount(null);
      session.replaceAccount('a');
      pending.complete([favoriteForMovie(550)]);
      await refresh;
      expect(vm.isCurrent, isFalse);
      expect(vm.items, isEmpty);
      expect(movies.detailIds, isEmpty);
    },
  );

  testWidgets('favorites refresh after detail and use the new login session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tokens = MemoryTokenStorage()..token = 'account-a-token';
    final member = _MemberFixture();
    final auth = AuthViewModel(_LoginFixture(), member, tokens);
    addTearDown(auth.dispose);
    await auth.restoreSession();
    final favorites = FavoriteFixture({550, 551})
      ..readList = () => auth.member?.email == 'b@example.com'
          ? [favoriteForMovie(777)]
          : null;

    await tester.pumpWidget(
      MovieLogApp(
        initialLocation: '/my',
        authViewModel: auth,
        movieService: FakeTmdbService(),
        genrePreferences: MemoryGenrePreferences(),
        favoriteApiService: favorites,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 즐겨찾기'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.text('영화 550'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('즐겨찾기 해제'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('즐겨찾기 등록'), findsOneWidget);
    expect(find.text('즐겨찾기에서 삭제했어요.'), findsOneWidget);
    await tester.tap(find.byTooltip('즐겨찾기 등록'));
    await tester.pumpAndSettle();
    expect(find.text('즐겨찾기에 추가했어요.'), findsOneWidget);
    await tester.tap(find.byTooltip('즐겨찾기 해제'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.text('영화 550'), findsNothing);
    expect(find.text('영화 551'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    member.account = 'b';
    await auth.login('b@example.com', 'test-password');
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('내 즐겨찾기'));
    await tester.pumpAndSettle();
    expect(find.text('영화 551'), findsNothing);
    expect(find.text('영화 777'), findsOneWidget);
  });
}

Map<String, Object?> _response(Object? result) => {
  'isSuccess': true,
  'code': 'OK',
  'message': 'OK',
  'result': result,
};

DioException _httpError(int status, String code) {
  final options = RequestOptions();
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {'code': code},
    ),
  );
}

class _LoginFixture implements AuthApiService {
  @override
  Future<LoginResult> login(LoginRequest request) async =>
      const LoginResult(accessToken: 'account-b-token', nickname: 'b');
}

class _MemberFixture extends MemberApiService {
  _MemberFixture() : super(Dio());

  String account = 'a';

  @override
  Future<MemberInfo> fetchMe() async => MemberInfo(
    email: '$account@example.com',
    nickname: account,
    createdAt: DateTime.utc(2026),
  );
}
