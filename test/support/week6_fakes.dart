import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

class FakeMemberCheckService implements MemberCheckService {
  FutureOr<bool> Function(String)? onNickname;
  FutureOr<bool> Function(String)? onEmail;
  final nicknames = <String>[];
  final emails = <String>[];

  @override
  Future<bool> checkNickname(String value) async {
    nicknames.add(value);
    return onNickname == null ? true : await onNickname!(value);
  }

  @override
  Future<bool> checkEmail(String value) async {
    emails.add(value);
    return onEmail == null ? true : await onEmail!(value);
  }
}

class FakeRatingApiService implements RatingApiService {
  FutureOr<List<RatingDto>> Function(int)? onFetch;
  final memberIds = <int>[];

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    memberIds.add(memberId);
    return onFetch == null ? [testRating()] : await onFetch!(memberId);
  }
}

RatingDto testRating({int id = 1, int movieId = 550, String? comment}) =>
    RatingDto(
      ratingId: id,
      movieId: movieId,
      score: 5,
      comment: comment,
      createdAt: DateTime.utc(2026, 10, 30),
    );

DioException testHttpError({int? status}) {
  final request = RequestOptions(path: '/test');
  return DioException(
    requestOptions: request,
    type: status == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response<dynamic>(requestOptions: request, statusCode: status),
  );
}
