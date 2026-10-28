import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_request_state.dart';

class MovieDetailViewModel extends MovieRequestViewModel {
  MovieDetailViewModel(
    this._service, {
    required this.movieId,
    TmdbMovieDto? initialMovie,
  }) : _movie = initialMovie?.id == movieId ? initialMovie : null;

  final TmdbMovieService _service;
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
}
