import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._service, this._movieService, this.memberId);
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final int memberId;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  String? refreshWarning;
  final Set<int> selectedRatingIds = {};
  bool isEditing = false;
  bool isDeletingSelected = false;

  bool _isCurrent(int version) => !_disposed && version == _requestVersion;

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (!_isCurrent(version)) return;
      final entries = <RatingWithMovie>[];
      final attemptedMovies = <int>{};
      var missingMovies = 0;
      for (final rating in rawRatings) {
        if (!_isCurrent(version)) return;
        TmdbMovieDto? movie;
        if (_movieCache.containsKey(rating.movieId)) {
          movie = _movieCache[rating.movieId];
        } else if (attemptedMovies.add(rating.movieId)) {
          try {
            movie = await _movieService.fetchMovie(rating.movieId);
            if (!_isCurrent(version)) return;
            _movieCache[rating.movieId] = movie;
          } on DioException catch (error) {
            if (!_isCurrent(version)) return;
            // Only a definitive 404 is cached. Temporary errors retry next load.
            if (error.response?.statusCode == 404) {
              _movieCache[rating.movieId] = null;
            }
          } on FormatException {
            if (!_isCurrent(version)) return;
          } on TypeError {
            if (!_isCurrent(version)) return;
          }
        }
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (!_isCurrent(version)) return;
      ratings = List.unmodifiable(entries);
      status = ratings.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      refreshWarning = null;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } on FormatException {
      if (!_isCurrent(version)) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 응답을 읽지 못했습니다. 다시 시도해 주세요.';
    } on TypeError {
      if (!_isCurrent(version)) return;
      status = MyRatingsLoadStatus.error;
      message = '평점 응답을 읽지 못했습니다. 다시 시도해 주세요.';
    }
    if (_isCurrent(version)) notifyListeners();
  }

  Future<void> _refreshAfterWrite() async {
    await load();
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      notifyListeners();
    }
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    try {
      await _service.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      final text = serverErrorMessage(
        error,
        fallback: '수정하지 못했습니다. 다시 시도해 주세요.',
      );
      if (shouldRefreshAfterRatingError(error)) await load();
      throw RatingWriteException(text);
    }
    await _refreshAfterWrite();
  }

  Future<void> deleteRating(int ratingId) async {
    try {
      await _service.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      final text = serverErrorMessage(
        error,
        fallback: '삭제하지 못했습니다. 다시 시도해 주세요.',
      );
      if (shouldRefreshAfterRatingError(error)) await load();
      throw RatingWriteException(text);
    }
    await _refreshAfterWrite();
  }

  void startEditing() {
    if (_disposed || isDeletingSelected) return;
    isEditing = true;
    selectedRatingIds.clear();
    notifyListeners();
  }

  void cancelEditing() {
    if (_disposed || isDeletingSelected) return;
    isEditing = false;
    selectedRatingIds.clear();
    notifyListeners();
  }

  void selectRating(int id, bool selected) {
    if (_disposed || isDeletingSelected) return;
    if (selected) {
      selectedRatingIds.add(id);
    } else {
      selectedRatingIds.remove(id);
    }
    notifyListeners();
  }

  /// Returns the number of failed requests. Successful IDs are not retried.
  Future<int> deleteSelectedRatings() async {
    if (_disposed || isDeletingSelected || selectedRatingIds.isEmpty) return 0;
    isDeletingSelected = true;
    notifyListeners();
    var failed = 0;
    final serviceRequestCount = selectedRatingIds.length;
    try {
      for (final id in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(memberId: memberId, ratingId: id);
          selectedRatingIds.remove(id);
        } catch (_) {
          failed++;
        }
      }
      if (failed < serviceRequestCount) {
        await _refreshAfterWrite();
      } else {
        await load();
      }
      return failed;
    } finally {
      isDeletingSelected = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
