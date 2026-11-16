import 'package:dio/dio.dart';
import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/json_values.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';
class RatingApiService {
  RatingApiService(this._publicDio, [Dio? authDio]) : _authDio = authDio ?? _publicDio;
  final Dio _publicDio;
  final Dio _authDio;
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get<dynamic>('/v7/members/$memberId/ratings');
    if (response.data is! List) throw const FormatException('Expected a rating array.');
    return List.unmodifiable((response.data as List).map((item) => RatingDto.fromJson(jsonObject(item))));
  }
  RatingDto _rating(Object? data) {
    final common = CommonResponse<RatingDto>.fromJson(data, (v) => RatingDto.fromJson(jsonObject(v)));
    if (!common.isSuccess || common.result == null) throw const FormatException('Invalid rating response.');
    return common.result!;
  }
  Future<RatingDto> createRating({required CreateRatingRequest request}) async {
    validateServerScore(request.score.toDouble());
    final response = await _authDio.post<dynamic>('/v7/ratings', data: request.toJson());
    if (response.statusCode != 201) throw const FormatException('Unexpected rating creation status.');
    return _rating(response.data);
  }
  Future<RatingDto> updateRating({required int ratingId, required int score, String? comment}) async {
    validateServerScore(score.toDouble());
    final response = await _authDio.patch<dynamic>('/v7/ratings/$ratingId', data: {'score': score, 'comment': comment});
    if (response.statusCode != 200) throw const FormatException('Unexpected rating update status.');
    return _rating(response.data);
  }
  Future<void> deleteRating({required int ratingId}) async {
    final response = await _authDio.delete<dynamic>('/v7/ratings/$ratingId');
    if (response.statusCode != 200) throw const FormatException('Unexpected rating deletion status.');
    final result = CommonResponse<Object?>.fromJson(response.data, (value) => value);
    if (!result.isSuccess || result.result != null) throw const FormatException('Invalid delete response.');
  }
}
String ratingErrorMessage(DioException error) => switch (apiErrorCode(error)) {
  'RATING403_1' => '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.',
  'RATING409_1' => '이미 평점을 남긴 영화예요. 기존 기록을 확인해 주세요.',
  'RATING404_1' => '해당 평점을 찾을 수 없어요.',
  'COMMON400' => apiErrorMessage(error) ?? '평점을 확인해 주세요.',
  _ => '요청하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.',
};
class RatingWriteException implements Exception {
  const RatingWriteException(this.message);
  final String message;
}
