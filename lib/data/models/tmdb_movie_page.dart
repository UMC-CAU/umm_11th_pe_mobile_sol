import 'json_values.dart';
import 'tmdb_movie_dto.dart';

class TmdbMoviePageDto {
  const TmdbMoviePageDto({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  final int page;
  final List<TmdbMovieDto> results;
  final int totalPages;
  final int totalResults;

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] ?? const [];
    if (rawResults is! List) {
      throw const FormatException('Invalid TMDB results array.');
    }
    if (json['page'] is! num ||
        json['total_pages'] is! num ||
        json['total_results'] is! num) {
      throw const FormatException('Missing TMDB page metadata.');
    }
    return TmdbMoviePageDto(
      page: jsonInt(json['page']),
      results: List.unmodifiable(
        rawResults.map((item) => TmdbMovieDto.fromJson(jsonObject(item))),
      ),
      totalPages: jsonInt(json['total_pages']),
      totalResults: jsonInt(json['total_results']),
    );
  }
}
