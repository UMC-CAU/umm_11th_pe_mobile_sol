import 'package:dio/dio.dart';

import '../../core/config/movie_log_config.dart';
import '../../core/network/auth_interceptor.dart';
import '../models/common_response.dart';
import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';
import '../models/json_values.dart';

class FavoriteApiService {
  FavoriteApiService(this._dio, {int Function()? sessionVersion})
    : _sessionVersion = sessionVersion;

  final Dio _dio;
  final int Function()? _sessionVersion;
  static const _path = '${MovieLogConfig.apiPrefix}/favorites';

  Future<FavoriteResponseDto> add(int movieId) async {
    final response = await _dio.post<dynamic>(
      _path,
      data: {'movieId': movieId},
      options: _sessionOptions(),
    );
    final favorite = _readResult(
      response,
      201,
      (value) => FavoriteResponseDto.fromJson(jsonObject(value)),
    );
    if (favorite.movieId != movieId) {
      throw const FormatException('Favorite movie ID mismatch.');
    }
    return favorite;
  }

  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _dio.get<dynamic>(_path, options: _sessionOptions());
    return _readResult(response, 200, (value) {
      if (value is! List) {
        throw const FormatException('Expected a favorite array.');
      }
      return List<FavoriteResponseDto>.unmodifiable(
        value.map((item) => FavoriteResponseDto.fromJson(jsonObject(item))),
      );
    });
  }

  Future<FavoriteCheckDto> getStatus(int movieId) async {
    final response = await _dio.get<dynamic>(
      '$_path/$movieId',
      options: _sessionOptions(),
    );
    return _readResult(
      response,
      200,
      (value) => FavoriteCheckDto.fromJson(jsonObject(value), movieId: movieId),
    );
  }

  Future<void> remove(int movieId) async {
    final response = await _dio.delete<dynamic>(
      '$_path/$movieId',
      options: _sessionOptions(),
    );
    final common = CommonResponse<Object?>.fromJson(
      response.data,
      (value) => value,
    );
    if (response.statusCode != 200 ||
        !common.isSuccess ||
        common.result != null) {
      throw const FormatException('Invalid favorite deletion response.');
    }
  }

  Options? _sessionOptions() {
    final version = _sessionVersion?.call();
    return version == null
        ? null
        : Options(extra: {AuthInterceptor.expectedSessionVersion: version});
  }

  T _readResult<T extends Object>(
    Response<dynamic> response,
    int expectedStatus,
    T Function(Object?) parse,
  ) {
    final common = CommonResponse<T>.fromJson(response.data, parse);
    final result = common.result;
    if (response.statusCode != expectedStatus ||
        !common.isSuccess ||
        result == null) {
      throw const FormatException('Invalid favorite API response.');
    }
    return result;
  }
}
