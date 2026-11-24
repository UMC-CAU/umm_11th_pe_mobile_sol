import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';

String movieYear(TmdbMovieDto movie) =>
    DateTime.tryParse(movie.releaseDate ?? '')?.year.toString() ?? '';

String movieGenreLabel(
  TmdbMovieDto movie, [
  List<TmdbGenreDto> catalog = const [],
]) {
  final genres = movie.genres.isNotEmpty
      ? movie.genres
      : catalog.where((genre) => movie.genreIds.contains(genre.id)).toList();
  return genres.map((genre) => genre.name).join(' · ');
}

String movieMetadata(TmdbMovieDto movie) => [
  movieYear(movie),
  if (movie.genres.isNotEmpty) movieGenreLabel(movie),
  if (movie.runtime != null && movie.runtime! > 0) '${movie.runtime}분',
].where((value) => value.isNotEmpty).join(' · ');
