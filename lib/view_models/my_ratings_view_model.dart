import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/api_error.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_ratings.dart';
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._session, this._auth) { _session.addListener(_changed); }
  final RatingApiService _service;
  final SessionRatings _session;
  final AuthViewModel _auth;
  bool _disposed = false;
  List<RatingWithMovie> get ratings => _session.ratings;
  void _changed() { if (!_disposed) notifyListeners(); }
  bool _current(int version) => !_disposed && version == _auth.sessionVersion && _auth.status == AuthStatus.signedIn;
  Future<void> updateRating({required int ratingId, required int score, String? comment}) async {
    final version = _auth.sessionVersion;
    try {
      final result = await _service.updateRating(ratingId: ratingId, score: score, comment: comment);
      if (!_current(version)) throw const RatingWriteException('세션이 변경되어 결과를 반영하지 못했어요.');
      _session.update(result, version);
    } on DioException catch (error) {
      if (_current(version) && apiErrorCode(error) == 'RATING404_1') _session.remove(ratingId, version);
      throw RatingWriteException(ratingErrorMessage(error));
    }
  }
  Future<void> deleteRating(int ratingId) async {
    final version = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId: ratingId);
      if (!_current(version)) throw const RatingWriteException('세션이 변경되어 결과를 반영하지 못했어요.');
      _session.remove(ratingId, version);
    } on DioException catch (error) {
      if (_current(version) && apiErrorCode(error) == 'RATING404_1') _session.remove(ratingId, version);
      throw RatingWriteException(ratingErrorMessage(error));
    }
  }
  @override
  void dispose() { _disposed = true; _session.removeListener(_changed); super.dispose(); }
}
