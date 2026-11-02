import 'package:dio/dio.dart';

import '../models/json_values.dart';
import '../models/rating_dto.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get<dynamic>('/v5/members/$memberId/ratings');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Expected a bare v5 rating array.');
    }
    return List.unmodifiable(
      data.map((item) => RatingDto.fromJson(jsonObject(item))),
    );
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  return switch (error.response?.statusCode) {
    400 => 'memberId 형식을 다시 확인해 주세요.',
    404 => '존재하지 않는 회원입니다.',
    _ => '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
  };
}
