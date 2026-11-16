import 'package:dio/dio.dart';

import '../../core/config/tmdb_config.dart';
import '../models/json_values.dart';
import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_dto.dart';
import '../models/tmdb_movie_page.dart';

/// Stateless HTTP + DTO conversion only. Limits, pagination loops and the
/// selected genres belong to the page's ViewModel.
class TmdbMovieService {
  TmdbMovieService(this._dio);

  final Dio _dio;

  Future<TmdbMoviePageDto> fetchPopular({
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '/movie/popular',
      queryParameters: {'language': TmdbConfig.language, 'page': page},
      cancelToken: cancelToken,
    );
    return TmdbMoviePageDto.fromJson(jsonObject(response.data));
  }

  Future<TmdbMoviePageDto> discoverMovies({
    int page = 1,
    List<int>? genreIds,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '/discover/movie',
      queryParameters: {
        'language': TmdbConfig.language,
        'page': page,
        'include_adult': false,
        'sort_by': 'popularity.desc',
        if (genreIds != null && genreIds.isNotEmpty)
          'with_genres': genreIds.join('|'),
      },
      cancelToken: cancelToken,
    );
    return TmdbMoviePageDto.fromJson(jsonObject(response.data));
  }

  Future<List<TmdbGenreDto>> fetchGenres({CancelToken? cancelToken}) async {
    final response = await _dio.get<dynamic>(
      '/genre/movie/list',
      queryParameters: {'language': TmdbConfig.language},
      cancelToken: cancelToken,
    );
    final genres = jsonObject(response.data)['genres'];
    if (genres is! List) {
      throw const FormatException('Missing TMDB genres array.');
    }
    return List.unmodifiable(
      genres.map((item) => TmdbGenreDto.fromJson(jsonObject(item))),
    );
  }

  Future<TmdbMovieDto> fetchMovie(
    int movieId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<dynamic>(
      '/movie/$movieId',
      queryParameters: {'language': TmdbConfig.language},
      cancelToken: cancelToken,
    );
    return TmdbMovieDto.fromJson(jsonObject(response.data));
  }
}
