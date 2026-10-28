import 'dart:async';

import 'package:dio/dio.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/local/movie_genre_preferences.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

const testGenres = [
  TmdbGenreDto(id: 28, name: '액션'),
  TmdbGenreDto(id: 18, name: '드라마'),
  TmdbGenreDto(id: 878, name: 'SF'),
];

TmdbMovieDto testMovie(int id) => TmdbMovieDto(
  id: id,
  title: '영화 $id',
  posterPath: null,
  backdropPath: null,
  popularity: 0,
  releaseDate: '2026-10-01',
  voteAverage: 8.2,
  genreIds: const [28],
  overview: '테스트용 영화의 줄거리입니다.',
);

TmdbMoviePageDto testPage(
  Iterable<int> ids, {
  int page = 1,
  int totalPages = 1,
}) => TmdbMoviePageDto(
  page: page,
  results: ids.map(testMovie).toList(),
  totalPages: totalPages,
  totalResults: 100,
);

class MemoryGenrePreferences implements MovieGenrePreferences {
  MemoryGenrePreferences({
    this.ids = const [],
    this.failRead = false,
    this.failWrite = false,
  });
  List<int> ids;
  final bool failRead;
  final bool failWrite;

  @override
  Future<List<int>> read(List<TmdbGenreDto> genres) async {
    if (failRead) throw StateError('Storage unavailable.');
    return ids;
  }

  @override
  Future<void> write(List<int> ids, List<TmdbGenreDto> genres) async {
    if (failWrite) throw StateError('Storage unavailable.');
    this.ids = List.of(ids);
  }
}

class FakeTmdbService implements TmdbMovieService {
  FutureOr<TmdbMoviePageDto> Function(int page, List<int>? ids)? onDiscover;
  FutureOr<TmdbMoviePageDto> Function()? onPopular;
  FutureOr<List<TmdbGenreDto>> Function()? onGenres;
  FutureOr<TmdbMovieDto> Function(int id)? onDetail;
  int popularCalls = 0;
  int genreCalls = 0;
  final detailIds = <int>[];
  final requests = <({int page, List<int>? ids})>[];
  CancelToken? lastCancelToken;

  @override
  Future<TmdbMoviePageDto> fetchPopular({
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    popularCalls++;
    return onPopular == null
        ? testPage([1, 2, 3, 4, 5, 6])
        : await onPopular!();
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres({CancelToken? cancelToken}) async {
    genreCalls++;
    return onGenres == null ? testGenres : await onGenres!();
  }

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    int page = 1,
    List<int>? genreIds,
    CancelToken? cancelToken,
  }) async {
    requests.add((
      page: page,
      ids: genreIds == null ? null : List.of(genreIds),
    ));
    lastCancelToken = cancelToken;
    return onDiscover == null
        ? testPage([101, 202])
        : await onDiscover!(page, genreIds);
  }

  @override
  Future<TmdbMovieDto> fetchMovie(
    int movieId, {
    CancelToken? cancelToken,
  }) async {
    detailIds.add(movieId);
    return onDetail == null ? testMovie(movieId) : await onDetail!(movieId);
  }
}
