import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'support/capturing_adapter.dart';
import 'support/week6_fakes.dart';

DioException httpError(int status, String message) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: {
        'isSuccess': false,
        'code': 'COMMON$status',
        'message': message,
        'result': null,
      },
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  test(
    'signup sends trimmed identity and unchanged password, then reads memberId',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      addTearDown(() => dio.close(force: true));
      final adapter = CapturingAdapter()
        ..status = 201
        ..body = {
          'isSuccess': true,
          'code': 'COMMON201',
          'message': 'ok',
          'result': {'memberId': 37, 'email': 'a@b.com', 'nickname': '한솔'},
        };
      dio.httpClientAdapter = adapter;
      final response = await SignUpService(dio).signUp(
        const CreateMemberRequest(
          email: ' a@b.com ',
          nickname: ' 한솔 ',
          password: ' Password1! ',
        ),
      );
      expect(response.result!.memberId, 37);
      expect(adapter.requests.single.path, '/v8/members');
      expect(adapter.requests.single.data, {
        'email': 'a@b.com',
        'nickname': '한솔',
        'password': ' Password1! ',
      });
    },
  );

  test(
    'v8 ratings use movieId, return objects, and delete with a 200 wrapper',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      addTearDown(() => dio.close(force: true));
      final adapter = CapturingAdapter()
        ..status = 201
        ..body = {
          'isSuccess': true,
          'code': 'OK',
          'message': 'ok',
          'result': {
            'ratingId': 12,
            'movieId': 550,
            'score': 5,
            'comment': '재밌다',
            'createdAt': '2026-11-01T00:00:00Z',
          },
        };
      dio.httpClientAdapter = adapter;
      final service = RatingApiService(dio, dio);
      final created = await service.createRating(
        request: const CreateRatingRequest(
          movieId: 550,
          score: 5,
          comment: ' 재밌다 ',
        ),
      );
      expect(created.ratingId, 12);
      expect(adapter.requests.last.path, '/v8/ratings');
      expect(adapter.requests.last.data, {
        'movieId': 550,
        'score': 5,
        'comment': '재밌다',
      });
      adapter.status = 200;
      await service.updateRating(ratingId: 12, score: 4, comment: null);
      expect(adapter.requests.last.path, '/v8/ratings/12');
      expect(adapter.requests.last.data, {'score': 4, 'comment': null});
      adapter.body = {
        'isSuccess': true,
        'code': 'OK',
        'message': 'ok',
        'result': null,
      };
      await service.deleteRating(ratingId: 12);
      expect(adapter.requests.last.method, 'DELETE');
      expect(() => validateServerScore(3.5), throwsArgumentError);
    },
  );

  test('signup separates password 400 and duplicate 409', () async {
    final service = FakeMemberCheckService();
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('한솔');
    vm.onEmailChanged('a@b.com');
    await vm.checkNickname('한솔');
    await vm.checkEmail('a@b.com');
    const request = CreateMemberRequest(
      email: 'a@b.com',
      nickname: '한솔',
      password: 'Password1!',
    );
    service.onSignUp = (_) => throw httpError(400, '비밀번호 형식 오류');
    await vm.submit(request);
    expect(vm.passwordErrorText, '비밀번호 형식 오류');
    expect(vm.snackbarMessage, isNull);
    vm.onPasswordChanged();
    service.onSignUp = (_) => throw httpError(409, '이미 사용 중인 이메일입니다.');
    await vm.submit(request);
    expect(vm.passwordErrorText, isNull);
    expect(vm.snackbarMessage, '이미 사용 중인 이메일입니다.');
  });
}
