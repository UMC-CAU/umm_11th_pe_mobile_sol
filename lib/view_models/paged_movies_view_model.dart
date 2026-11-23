import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import 'load_phase.dart';
import 'movie_request_state.dart';

typedef FetchMoviePage =
    Future<TmdbMoviePageDto> Function(int page, CancelToken cancelToken);

class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  static const _maxTmdbPage = 500;
  FetchMoviePage? _fetchPage;
  CancelToken? _cancelToken;
  int _generation = 0;
  int _nextPage = 1;
  int _totalPages = 0;
  final _moviesById = <int, TmdbMovieDto>{};
  LoadPhase _phase = LoadPhase.idle;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _loadMoreError;

  List<TmdbMovieDto> get movies => List.unmodifiable(_moviesById.values);
  LoadPhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _phase == LoadPhase.ready && _nextPage <= _totalPages;
  int get generation => _generation;

  Future<void> loadInitial(FetchMoviePage fetchPage) async {
    if (isDisposed) return;
    final token = CancelToken();
    _reset(fetchPage: fetchPage, token: token);
    final generation = _generation;
    notifyIfAlive();

    try {
      final page = await fetchPage(1, token);
      if (!_isCurrent(generation)) return;
      _applyPage(page, 1);
      _phase = _moviesById.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _errorMessage = movieErrorMessage(error);
      _phase = LoadPhase.error;
    }
    notifyIfAlive();
  }

  Future<void> refresh() async {
    final fetchPage = _fetchPage;
    if (fetchPage != null && _phase != LoadPhase.loading) {
      await loadInitial(fetchPage);
    }
  }

  void clear() {
    if (isDisposed) return;
    _reset();
    notifyIfAlive();
  }

  Future<void> loadNextPage() async {
    final fetchPage = _fetchPage;
    final token = _cancelToken;
    if (isDisposed ||
        !hasMore ||
        _isLoadingMore ||
        fetchPage == null ||
        token == null) {
      return;
    }
    final generation = _generation;
    final requestedPage = _nextPage;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyIfAlive();

    try {
      final page = await fetchPage(requestedPage, token);
      if (!_isCurrent(generation)) return;
      _applyPage(page, requestedPage);
    } catch (error) {
      if (_isCurrent(generation)) _loadMoreError = movieErrorMessage(error);
    } finally {
      if (_isCurrent(generation)) {
        _isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  void _applyPage(TmdbMoviePageDto page, int requestedPage) {
    if (page.page != requestedPage) {
      throw const FormatException('TMDB page number mismatch.');
    }
    for (final movie in page.results) {
      _moviesById.putIfAbsent(movie.id, () => movie);
    }
    _totalPages = page.totalPages.clamp(0, _maxTmdbPage);
    _nextPage = requestedPage + 1;
  }

  bool _isCurrent(int generation) => !isDisposed && _generation == generation;

  void _reset({FetchMoviePage? fetchPage, CancelToken? token}) {
    _generation++;
    _cancelToken?.cancel('The movie filters changed.');
    _fetchPage = fetchPage;
    _cancelToken = token;
    _nextPage = 1;
    _totalPages = 0;
    _moviesById.clear();
    _phase = token == null ? LoadPhase.idle : LoadPhase.loading;
    _isLoadingMore = false;
    _errorMessage = null;
    _loadMoreError = null;
  }

  @override
  void dispose() {
    _cancelToken?.cancel('The movies page was disposed.');
    super.dispose();
  }
}
