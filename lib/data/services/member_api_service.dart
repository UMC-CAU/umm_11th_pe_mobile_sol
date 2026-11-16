import 'package:dio/dio.dart';
import '../models/common_response.dart';
import '../models/json_values.dart';
import '../models/member_info.dart';
class MemberApiService {
  MemberApiService(this._dio);
  final Dio _dio;
  MemberInfo _parse(Object? value) {
    final common = CommonResponse<MemberInfo>.fromJson(value, (v) => MemberInfo.fromJson(jsonObject(v)));
    if (!common.isSuccess || common.result == null) throw const FormatException('Invalid member response.');
    return common.result!;
  }
  Future<MemberInfo> fetchMe() async => _parse((await _dio.get<dynamic>('/v7/members/me')).data);
  Future<MemberInfo> updateNickname(String nickname) async => _parse((await _dio.patch<dynamic>('/v7/members/me', data: {'nickname': nickname})).data);
}
