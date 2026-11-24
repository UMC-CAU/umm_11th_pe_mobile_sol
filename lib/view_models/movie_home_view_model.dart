import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_request_state.dart';

class MovieHomeViewModel extends MovieRequestViewModel {
  MovieHomeViewModel(this._service);

  final TmdbMovieService _service;
  MovieLoadStatus _status = MovieLoadStatus.idle;
  List<TmdbMovieDto> _movies = const [];
  String? _errorMessage;

  MovieLoadStatus get status => _status;
  List<TmdbMovieDto> get movies => _movies;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_status == MovieLoadStatus.loading) return;
    final token = beginRequest();
    _status = MovieLoadStatus.loading;
    _errorMessage = null;
    notifyState();
    try {
      final page = await _service.fetchPopular(cancelToken: token);
      if (!isCurrent(token)) return;
      _movies = List.unmodifiable(page.results.take(5));
      _status = _movies.isEmpty
          ? MovieLoadStatus.empty
          : MovieLoadStatus.success;
    } catch (error) {
      if (!isCurrent(token)) return;
      _errorMessage = movieErrorMessage(error);
      _status = MovieLoadStatus.error;
    }
    notifyState();
  }
}
