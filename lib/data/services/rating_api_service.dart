import 'package:dio/dio.dart';

import '../models/json_values.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';
import 'sign_up_service.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get<dynamic>('/v6/members/$memberId/ratings');
    if (response.data is! List) {
      throw const FormatException('Expected a bare v6 rating array.');
    }
    return List.unmodifiable(
      (response.data as List).map(
        (item) => RatingDto.fromJson(jsonObject(item)),
      ),
    );
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    validateServerScore(request.score.toDouble());
    final response = await _dio.post<dynamic>(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw const FormatException('Unexpected rating creation status.');
    }
    // The documented result varies between number and null; it is not needed.
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    final response = await _dio.patch<dynamic>(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    if (response.statusCode != 200) {
      throw const FormatException('Unexpected rating update status.');
    }
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete<dynamic>(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
      throw const FormatException('Unexpected rating deletion status.');
    }
    // 204 intentionally has no body to parse.
  }
}

String writeMyRatingsErrorMessage(DioException error) => serverErrorMessage(
  error,
  fallback: switch (error.response?.statusCode) {
    400 => 'memberId 형식을 다시 확인해 주세요.',
    404 => '존재하지 않는 회원입니다.',
    _ => '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
  },
);

bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code'] : null;
  return code == 'COMMON403' ||
      code == 'COMMON404' ||
      error.response?.statusCode == 403 ||
      error.response?.statusCode == 404;
}

class RatingWriteException implements Exception {
  const RatingWriteException(this.message);
  final String message;
}
