import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/local/movie_genre_preferences.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_request_state.dart';

enum MovieSort {
  original('기본순'),
  rating('평점순'),
  newest('최신순');

  const MovieSort(this.label);
  final String label;
}

class MovieListViewModel extends MovieRequestViewModel {
  MovieListViewModel(
    this._service,
    this._preferences, {
    List<int>? initialGenreIds,
    String? initialGenreName,
  }) : _initialGenreIds = initialGenreIds,
       _initialGenreName = initialGenreName;

  final TmdbMovieService _service;
  final MovieGenrePreferences _preferences;
  final List<int>? _initialGenreIds;
  final String? _initialGenreName;
  bool _ready = false;
  bool _hasSuccessfulSnapshot = false;
  List<TmdbGenreDto> _genres = const [];
  List<int> _selectedGenreIds = const [];
  List<int> _displayedGenreIds = const [];
  List<int> _lastSuccessfulGenreIds = const [];
  List<TmdbMovieDto> _movies = const [];
  List<TmdbMovieDto> _lastSuccessfulMovies = const [];
  MovieLoadStatus _status = MovieLoadStatus.idle;
  MovieSort _sort = MovieSort.original;
  String _query = '';
  String? _errorMessage;
  String? _preferenceMessage;
  int _failureVersion = 0;
  Future<void> _saveQueue = Future<void>.value();

  MovieLoadStatus get status => _status;
  bool get isLoading => _status == MovieLoadStatus.loading;
  bool get canSelectGenres => _ready && !isLoading;
  List<TmdbGenreDto> get genres => _genres;
  List<int> get selectedGenreIds => _selectedGenreIds;
  List<TmdbMovieDto> get movies => _movies;
  MovieSort get sort => _sort;
  String? get errorMessage => _errorMessage;
  String? get preferenceMessage => _preferenceMessage;
  int get failureVersion => _failureVersion;
  bool get showingPreviousGenre =>
      !listEquals(_selectedGenreIds, _displayedGenreIds);
  String get displayedGenreLabel => _displayedGenreIds.isEmpty
      ? '전체'
      : _genres
            .where((genre) => _displayedGenreIds.contains(genre.id))
            .map((genre) => genre.name)
            .join(' · ');

  List<TmdbMovieDto> get visibleMovies {
    final keyword = _query.trim().toLowerCase();
    final result = _movies
        .where((movie) => movie.title.toLowerCase().contains(keyword))
        .toList();
    if (_sort != MovieSort.original) {
      final indices = {
        for (var i = 0; i < _movies.length; i++) _movies[i].id: i,
      };
      result.sort((a, b) {
        final comparison = _sort == MovieSort.rating
            ? b.voteAverage.compareTo(a.voteAverage)
            : (b.releaseDate ?? '').compareTo(a.releaseDate ?? '');
        return comparison != 0
            ? comparison
            : indices[a.id]!.compareTo(indices[b.id]!);
      });
    }
    return result;
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyState();
  }

  void setSort(MovieSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyState();
  }

  Future<void> selectGenres(List<int> ids) async {
    if (!canSelectGenres) return;
    final allowed = _genres.map((genre) => genre.id).toSet();
    final next = ids.where(allowed.contains).toSet().toList()..sort();
    if (listEquals(next, _selectedGenreIds)) return;
    _selectedGenreIds = List.unmodifiable(next);
    _persistSelection();
    await load(clearMovies: true);
  }

  void _persistSelection() {
    final ids = List<int>.of(_selectedGenreIds);
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _preferences.write(ids, _genres);
        _preferenceMessage = null;
      } catch (_) {
        _preferenceMessage = '선택한 장르를 저장하지 못했어요. 현재 목록은 계속 볼 수 있어요.';
      }
      notifyState();
    });
    unawaited(_saveQueue);
  }

  Future<void> load({bool clearMovies = false}) async {
    // Both UI controls and this guard block duplicate refresh/filter requests.
    if (isLoading) return;
    final token = beginRequest();
    _status = MovieLoadStatus.loading;
    _errorMessage = null;
    if (clearMovies) _movies = const [];
    notifyState();
    try {
      if (!_ready) {
        final genres = await _service.fetchGenres(cancelToken: token);
        if (!isCurrent(token)) return;
        _genres = List.unmodifiable(genres);
        List<int> restored = const [];
        if (_initialGenreIds != null) {
          restored = _initialGenreIds;
        } else if (_initialGenreName != null) {
          restored = [
            for (final genre in genres)
              if (genre.name == _initialGenreName) genre.id,
          ];
        } else {
          try {
            restored = await _preferences.read(genres);
          } catch (_) {
            _preferenceMessage = '저장한 장르를 읽지 못해 전체 영화를 표시해요.';
          }
        }
        if (!isCurrent(token)) return;
        final allowed = genres.map((genre) => genre.id).toSet();
        final selected = restored.where(allowed.contains).toSet().toList()
          ..sort();
        _selectedGenreIds = List.unmodifiable(selected);
        _ready = true;
      }

      // Snapshot the request condition; every page uses these same IDs.
      final ids = List<int>.of(_selectedGenreIds);
      final byId = <int, TmdbMovieDto>{};
      var pageNumber = 1;
      var hasNextPage = true;
      while (byId.length < 30 && hasNextPage) {
        final page = await _service.discoverMovies(
          page: pageNumber,
          genreIds: ids.isEmpty ? null : ids,
          cancelToken: token,
        );
        if (!isCurrent(token)) return;
        for (final movie in page.results) {
          byId[movie.id] = movie;
          if (byId.length == 30) break;
        }
        hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
        pageNumber++;
      }
      _movies = List.unmodifiable(byId.values.take(30));
      _lastSuccessfulMovies = _movies;
      _displayedGenreIds = List.unmodifiable(ids);
      _lastSuccessfulGenreIds = _displayedGenreIds;
      _hasSuccessfulSnapshot = true;
      _status = _movies.isEmpty
          ? MovieLoadStatus.empty
          : MovieLoadStatus.success;
    } catch (error) {
      if (!isCurrent(token)) return;
      // Publish a complete result only: a failure on page 2 must not replace a
      // successful list with a partial page 1 result.
      if (_hasSuccessfulSnapshot) {
        _movies = _lastSuccessfulMovies;
        _displayedGenreIds = _lastSuccessfulGenreIds;
      }
      _errorMessage = movieErrorMessage(error);
      _status = MovieLoadStatus.error;
      _failureVersion++;
    }
    notifyState();
  }

  Future<void> refresh() => load();
  Future<void> retry() => load();
}
