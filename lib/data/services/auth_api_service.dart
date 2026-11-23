import 'package:dio/dio.dart';

import '../../core/config/movie_log_config.dart';
import '../models/common_response.dart';
import '../models/json_values.dart';
import '../models/login_models.dart';

class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;
  Future<LoginResult> login(LoginRequest request) async {
    final response = await _dio.post<dynamic>(
      '${MovieLogConfig.apiPrefix}/auth/login',
      data: request.toJson(),
    );
    final common = CommonResponse<LoginResult>.fromJson(
      response.data,
      (value) => LoginResult.fromJson(jsonObject(value)),
    );
    if (!common.isSuccess ||
        common.result == null ||
        common.result!.accessToken.isEmpty) {
      throw const FormatException('Invalid login response.');
    }
    return common.result!;
  }
}
