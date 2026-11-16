import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/json_values.dart';

class SignUpService {
  SignUpService(this._dio);
  final Dio _dio;

  Future<bool> checkNickname(String nickname) async {
    final response = await _dio.get<dynamic>(
      '/v6/members/nickname/${Uri.encodeComponent(nickname.trim())}',
    );
    return CheckResult.fromJson(jsonObject(response.data)).available;
  }

  Future<bool> checkEmail(String email) async {
    final response = await _dio.get<dynamic>(
      '/v6/members/email/${Uri.encodeComponent(email.trim())}',
    );
    return CheckResult.fromJson(jsonObject(response.data)).available;
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post<dynamic>(
      '/v6/members',
      data: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw const FormatException('Unexpected signup status.');
    }
    final result = CommonResponse<SignUpResult>.fromJson(
      response.data,
      (v) => SignUpResult.fromJson(jsonObject(v)),
    );
    if (!result.isSuccess ||
        result.result == null ||
        result.result!.memberId <= 0) {
      throw const FormatException('Signup response is missing memberId.');
    }
    return result;
  }
}

String serverErrorMessage(
  DioException error, {
  String fallback = '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.',
}) {
  final data = error.response?.data;
  if (data is Map &&
      data['message'] is String &&
      (data['message'] as String).trim().isNotEmpty) {
    return data['message'] as String;
  }
  return fallback;
}
