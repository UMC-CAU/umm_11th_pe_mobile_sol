import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

class FakeMemberCheckService implements MemberCheckService {
  FutureOr<bool> Function(String)? onNickname;
  FutureOr<bool> Function(String)? onEmail;
  FutureOr<CommonResponse<SignUpResult>> Function(CreateMemberRequest)?
  onSignUp;
  final signUpRequests = <CreateMemberRequest>[];
  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    signUpRequests.add(request);
    if (onSignUp != null) return await onSignUp!(request);
    return CommonResponse(
      isSuccess: true,
      code: 'COMMON201',
      message: 'ok',
      result: SignUpResult(
        memberId: 1,
        email: request.email,
        nickname: request.nickname,
      ),
    );
  }

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
  FutureOr<void> Function(int memberId, CreateRatingRequest request)? onCreate;
  FutureOr<void> Function(
    int memberId,
    int ratingId,
    int score,
    String? comment,
  )?
  onUpdate;
  FutureOr<void> Function(int memberId, int ratingId)? onDelete;
  final created = <CreateRatingRequest>[];
  final deleted = <int>[];
  @override
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    created.add(request);
    await onCreate?.call(memberId, request);
  }

  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await onUpdate?.call(memberId, ratingId, score, comment);
  }

  @override
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    deleted.add(ratingId);
    await onDelete?.call(memberId, ratingId);
  }

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
