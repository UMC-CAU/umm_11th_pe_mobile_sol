import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/local/movie_genre_preferences.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import '../data/services/tmdb_movie_service.dart';
import 'paged_movies_view_model.dart';

enum MovieSort {
  original('기본순'),
  rating('평점순'),
  newest('최신순');

  const MovieSort(this.label);
  final String label;
}

class MovieListViewModel extends PagedMoviesViewModel {
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

  bool _genresReady = false;
  List<TmdbGenreDto> _genres = const [];
  List<int> _selectedGenreIds = const [];
  MovieSort _sort = MovieSort.original;
  String? _preferenceMessage;
  Future<void> _saveQueue = Future<void>.value();

  bool get canSelectGenres => _genresReady;
  List<TmdbGenreDto> get genres => _genres;
  List<int> get selectedGenreIds => _selectedGenreIds;
  MovieSort get sort => _sort;
  String? get preferenceMessage => _preferenceMessage;

  List<TmdbMovieDto> get visibleMovies {
    final result = movies;
    if (_sort == MovieSort.original) return result;
    final sorted = result.indexed.toList();
    sorted.sort((a, b) {
      final comparison = _sort == MovieSort.rating
          ? b.$2.voteAverage.compareTo(a.$2.voteAverage)
          : (b.$2.releaseDate ?? '').compareTo(a.$2.releaseDate ?? '');
      return comparison != 0 ? comparison : a.$1.compareTo(b.$1);
    });
    return sorted.map((entry) => entry.$2).toList(growable: false);
  }

  void setSort(MovieSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyIfAlive();
  }

  Future<void> selectGenres(List<int> ids) async {
    if (!canSelectGenres || isDisposed) return;
    final next = _validSelection(ids, _genres);
    if (listEquals(next, _selectedGenreIds)) return;
    _selectedGenreIds = next;
    _persistSelection(next);
    await load();
  }

  Future<void> load() => loadInitial(_discoverPage);

  Future<TmdbMoviePageDto> _discoverPage(int page, CancelToken token) async {
    if (!_genresReady) await _restoreGenres(token);
    if (token.isCancelled) throw token.cancelError!;
    final ids = _selectedGenreIds;
    return _service.discoverMovies(
      page: page,
      genreIds: ids.isEmpty ? null : ids,
      cancelToken: token,
    );
  }

  Future<void> _restoreGenres(CancelToken token) async {
    final genres = await _service.fetchGenres(cancelToken: token);
    if (token.isCancelled) throw token.cancelError!;
    var restored = _initialGenreIds ?? const <int>[];
    String? preferenceMessage;
    if (_initialGenreIds == null) {
      if (_initialGenreName != null) {
        restored = [
          for (final genre in genres)
            if (genre.name == _initialGenreName) genre.id,
        ];
      } else {
        try {
          restored = await _preferences.read(genres);
        } catch (_) {
          preferenceMessage = '저장한 장르를 읽지 못해 전체 영화를 표시해요.';
        }
      }
    }
    if (token.isCancelled) throw token.cancelError!;
    _genres = List.unmodifiable(genres);
    _selectedGenreIds = _validSelection(restored, _genres);
    _preferenceMessage = preferenceMessage;
    _genresReady = true;
    notifyIfAlive();
  }

  List<int> _validSelection(List<int> ids, List<TmdbGenreDto> genres) {
    final allowed = genres.map((genre) => genre.id).toSet();
    final selection = ids.where(allowed.contains).toSet().toList()..sort();
    return List.unmodifiable(selection);
  }

  void _persistSelection(List<int> ids) {
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _preferences.write(ids, _genres);
        _preferenceMessage = null;
      } catch (_) {
        _preferenceMessage = '선택한 장르를 저장하지 못했어요. 현재 목록은 계속 볼 수 있어요.';
      }
      notifyIfAlive();
    });
    unawaited(_saveQueue);
  }
}
