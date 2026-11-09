import 'package:dio/dio.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_request_state.dart';

class MovieDetailViewModel extends MovieRequestViewModel {
  MovieDetailViewModel(
    this._service, {
    required this.movieId,
    this.ratingService,
    this.memberId,
    TmdbMovieDto? initialMovie,
  }) : _movie = initialMovie?.id == movieId ? initialMovie : null;

  final TmdbMovieService _service;
  final RatingApiService? ratingService;
  final int? memberId;
  bool isSubmitting = false;
  bool _detailDisposed = false;
  final int? movieId;
  TmdbMovieDto? _movie;
  MovieLoadStatus _status = MovieLoadStatus.idle;
  String? _errorMessage;

  TmdbMovieDto? get movie => _movie;
  MovieLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_status == MovieLoadStatus.loading) return;
    final id = movieId;
    if (id == null || id <= 0) {
      _status = MovieLoadStatus.error;
      _errorMessage = '올바른 영화 주소가 아니에요.';
      notifyState();
      return;
    }
    final token = beginRequest();
    _status = MovieLoadStatus.loading;
    _errorMessage = null;
    notifyState();
    try {
      final movie = await _service.fetchMovie(id, cancelToken: token);
      if (!isCurrent(token)) return;
      if (movie.id != id) {
        throw const FormatException('TMDB movie ID mismatch.');
      }
      _movie = movie;
      _status = MovieLoadStatus.success;
    } catch (error) {
      if (!isCurrent(token)) return;
      _errorMessage = movieErrorMessage(error);
      _status = MovieLoadStatus.error;
    }
    notifyState();
  }

  Future<void> createRating({required int score, String? comment}) async {
    final currentMovie = _movie;
    if (memberId == null || ratingService == null || currentMovie == null) {
      throw const RatingWriteException('먼저 회원가입을 완료해 주세요.');
    }
    if (isSubmitting) return;
    isSubmitting = true;
    notifyState();
    try {
      await ratingService!.createRating(
        memberId: memberId!,
        request: CreateRatingRequest(
          movieId: currentMovie.id,
          score: score,
          comment: comment,
        ),
      );
    } on DioException catch (error) {
      throw RatingWriteException(
        serverErrorMessage(error, fallback: '평점을 등록하지 못했습니다. 다시 시도해 주세요.'),
      );
    } finally {
      isSubmitting = false;
      if (!_detailDisposed) notifyState();
    }
  }

  @override
  void dispose() {
    _detailDisposed = true;
    super.dispose();
  }
}
