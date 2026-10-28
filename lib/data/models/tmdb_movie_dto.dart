import 'json_values.dart';
import 'tmdb_genre_dto.dart';

class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genreIds,
    required this.voteAverage,
    required this.popularity,
    this.voteCount = 0,
    this.genres = const [],
    this.runtime,
  });

  /// TMDB ID is also the future MovieLog CreateRatingRequest.movieId.
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final double popularity;
  final int voteCount;
  final List<int> genreIds;
  final List<TmdbGenreDto> genres;
  final int? runtime;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    final id = jsonInt(json['id']);
    if (id <= 0) throw const FormatException('Missing TMDB movie ID.');
    final genres = (json['genres'] as List? ?? const [])
        .map((item) => TmdbGenreDto.fromJson(jsonObject(item)))
        .toList();
    return TmdbMovieDto(
      id: id,
      title:
          jsonString(json['title']) ??
          jsonString(json['original_title']) ??
          '제목 없음',
      overview: jsonString(json['overview']) ?? '',
      posterPath: jsonString(json['poster_path']),
      backdropPath: jsonString(json['backdrop_path']),
      releaseDate: jsonString(json['release_date']),
      voteAverage: jsonDouble(json['vote_average']),
      popularity: jsonDouble(json['popularity']),
      voteCount: jsonInt(json['vote_count']),
      genreIds: List.unmodifiable(
        json['genre_ids'] is List
            ? (json['genre_ids'] as List).whereType<num>().map(
                (id) => id.toInt(),
              )
            : genres.map((genre) => genre.id),
      ),
      genres: List.unmodifiable(genres),
      runtime: json['runtime'] is num ? (json['runtime'] as num).toInt() : null,
    );
  }
}
