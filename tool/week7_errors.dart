// 캡처용: 실제 서버에 요청하지 않고 회원가입 POST의 오류 응답을 재현합니다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/services/sign_up_service.dart';

const scenario = String.fromEnvironment('SIGNUP_ERROR', defaultValue: 'duplicate409');

void main() {
  runApp(MovieLogApp(initialLocation: '/signup', memberCheckService: _DemoSignUpService()));
}

class _DemoSignUpService extends SignUpService {
  _DemoSignUpService() : super(Dio());

  @override
  Future<bool> checkNickname(String nickname) async => true;

  @override
  Future<bool> checkEmail(String email) async => true;

  @override
  Future<CommonResponse<SignUpResult>> signUp(CreateMemberRequest request) async {
    final status = scenario == 'duplicate409' ? 409 : 400;
    final message = switch (scenario) {
      'password400' => '비밀번호는 대문자/소문자/숫자/특수문자를 포함한 8자 이상이어야 합니다.',
      'other400' => '회원가입 요청 정보를 확인해 주세요.',
      _ => '이미 사용 중인 이메일입니다.',
    };
    final options = RequestOptions(path: '/v6/members');
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(requestOptions: options, statusCode: status,
        data: {'isSuccess': false, 'code': 'COMMON$status', 'message': message, 'result': null}),
    );
  }
}
