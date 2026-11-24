import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/models/favorite_response_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required FavoriteApiService favoriteApi,
    required TmdbMovieService tmdbApi,
    required SessionGuard session,
    required String accountId,
  }) : _favoriteApi = favoriteApi,
       _tmdbApi = tmdbApi,
       _session = session,
       _accountId = accountId,
       _generation = session.generation;

  final FavoriteApiService _favoriteApi;
  final TmdbMovieService _tmdbApi;
  final SessionGuard _session;
  final String _accountId;
  final int _generation;
  static const _maxConcurrentLookups = 5;

  final _cancelToken = CancelToken();
  LoadPhase _phase = LoadPhase.idle;
  String? _errorMessage;
  List<FavoriteResponseDto> _favorites = const [];
  Map<int, TmdbMovieDto> _moviesById = {};
  final _retries = <int, Future<TmdbMovieDto?>>{};

  bool get isCurrent =>
      !isDisposed && _session.isCurrent(_generation, _accountId);
  LoadPhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  List<FavoriteListItem> get items => [
    for (final favorite in _favorites)
      FavoriteListItem(
        favorite: favorite,
        movie: _moviesById[favorite.movieId],
      ),
  ];

  bool isRetrying(int movieId) => _retries.containsKey(movieId);
  bool canRetry(int movieId) =>
      isCurrent &&
      _phase == LoadPhase.ready &&
      !isRetrying(movieId) &&
      _retries.length < _maxConcurrentLookups;

  Future<void> refresh() async {
    if (!isCurrent || _phase == LoadPhase.loading) return;
    _phase = LoadPhase.loading;
    _errorMessage = null;
    notifyIfAlive();

    try {
      if (!isCurrent) return;
      final favorites = await _favoriteApi.fetchMyFavorites();
      if (!isCurrent) return;
      await Future.wait(_retries.values.toList());
      if (!isCurrent) return;
      final movies = await mapBounded(
        favorites.map((favorite) => favorite.movieId).toSet(),
        _maxConcurrentLookups,
        _fetchMovie,
      );
      if (!isCurrent) return;
      _favorites = favorites;
      _moviesById = {
        for (final movie in movies)
          if (movie != null) movie.id: movie,
      };
      _phase = favorites.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (error) {
      if (!isCurrent) return;
      _phase = LoadPhase.error;
      _errorMessage =
          error is DioException && apiErrorCode(error) == 'MEMBER404_1'
          ? '회원 정보를 찾지 못했어요.'
          : '내 즐겨찾기를 불러오지 못했어요.';
    }
    notifyIfAlive();
  }

  Future<void> retryMovie(int movieId) async {
    if (!canRetry(movieId) ||
        !_favorites.any((favorite) => favorite.movieId == movieId)) {
      return;
    }
    final request = _fetchMovie(movieId);
    _retries[movieId] = request;
    notifyIfAlive();
    final movie = await request;
    _retries.remove(movieId);
    if (!isCurrent || _phase != LoadPhase.ready) return;
    if (movie != null) _moviesById[movieId] = movie;
    notifyIfAlive();
  }

  Future<TmdbMovieDto?> _fetchMovie(int movieId) async {
    if (!isCurrent) return null;
    try {
      final movie = await _tmdbApi.fetchMovie(
        movieId,
        cancelToken: _cancelToken,
      );
      return movie.id == movieId ? movie : null;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _cancelToken.cancel('The favorites page was disposed.');
    super.dispose();
  }
}
