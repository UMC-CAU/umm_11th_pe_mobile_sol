import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

const int sampleMemberId = 1;

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

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
