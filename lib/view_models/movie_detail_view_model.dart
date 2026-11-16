import 'package:dio/dio.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_ratings.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_request_state.dart';

class MovieDetailViewModel extends MovieRequestViewModel {
  MovieDetailViewModel(
    this._service, {
    required this.movieId,
    this.ratingService,
    this.auth,
    this.sessionRatings,
    TmdbMovieDto? initialMovie,
  }) : _movie = initialMovie?.id == movieId ? initialMovie : null;

  final TmdbMovieService _service;
  final RatingApiService? ratingService;
  final AuthViewModel? auth;
  final SessionRatings? sessionRatings;
  bool get isSignedIn => auth?.status == AuthStatus.signedIn;
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
    final auth = this.auth;
    if (auth == null || auth.status != AuthStatus.signedIn || ratingService == null || currentMovie == null) throw const RatingWriteException('먼저 로그인해 주세요.');
    if (isSubmitting) return;
    final version = auth.sessionVersion; isSubmitting = true; notifyState();
    try {
      final rating = await ratingService!.createRating(request: CreateRatingRequest(movieId: currentMovie.id, score: score, comment: comment));
      if (_detailDisposed || version != auth.sessionVersion || auth.status != AuthStatus.signedIn) throw const RatingWriteException('세션이 변경되어 결과를 반영하지 못했어요.');
      sessionRatings?.add(rating, currentMovie, version);
    } on DioException catch (error) { throw RatingWriteException(ratingErrorMessage(error)); }
    finally { isSubmitting = false; if (!_detailDisposed) notifyState(); }
  }

  @override
  void dispose() {
    _detailDisposed = true;
    super.dispose();
  }
}
