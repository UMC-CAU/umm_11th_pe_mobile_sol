import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/movie_poster.dart';
import 'package:movielog/widgets/movie_metadata.dart';

void main() {
  test('snake_case, integer score and missing optional fields are safe', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 123,
      'title': '제목',
      'vote_average': 8,
      'poster_path': null,
      'backdrop_path': '/backdrop.jpg',
      'popularity': 102,
      'release_date': '',
      'genre_ids': [28, 18.0],
      'vote_count': 12.0,
    });
    expect(movie.id, 123);
    expect(movie.voteAverage, 8.0);
    expect(movie.voteCount, 12);
    expect(movie.genreIds, [28, 18]);
    expect(movie.posterPath, isNull);
    expect(movie.backdropPath, '/backdrop.jpg');
    expect(movie.popularity, 102.0);
    expect(movie.releaseDate, isNull);
    expect(movie.overview, '');
  });

  test('detail genres use ID/name objects and original title fallback', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 9,
      'original_title': 'Original',
      'genres': [
        {'id': 28, 'name': '액션'},
      ],
      'runtime': 125,
      'vote_average': 7.9,
    });
    expect(movie.title, 'Original');
    expect(movie.genreIds, [28]);
    expect(movie.genres.single.name, '액션');
    expect(movie.runtime, 125);
  });

  test(
    'missing identity or malformed page is an error, never a fake empty list',
    () {
      expect(
        () => TmdbMovieDto.fromJson({'title': 'No identity'}),
        throwsFormatException,
      );
      expect(
        () => TmdbMoviePageDto.fromJson({'success': false}),
        throwsFormatException,
      );
      final page = TmdbMoviePageDto.fromJson({
        'page': 1,
        'results': [],
        'total_pages': 0,
        'total_results': 0,
      });
      expect(page.results, isEmpty);
      expect(page.totalPages, 0);
    },
  );

  test('poster path is joined only when it is present and valid', () {
    expect(TmdbPoster.imageUrl(null), isNull);
    expect(TmdbPoster.imageUrl(''), isNull);
    expect(TmdbPoster.imageUrl('null'), isNull);
    expect(
      TmdbPoster.imageUrl('/poster.jpg'),
      'https://image.tmdb.org/t/p/w500/poster.jpg',
    );
  });
  test('null movie fields retain DTO defaults and omit date/genre display', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 20,
      'title': null,
      'overview': null,
      'poster_path': null,
      'backdrop_path': null,
      'release_date': null,
      'genre_ids': null,
      'vote_average': null,
      'popularity': null,
    });
    expect(movie.title, '제목 없음');
    expect(movie.overview, '');
    expect(movie.backdropPath, isNull);
    expect(movie.genreIds, isEmpty);
    expect(movie.voteAverage, 0.0);
    expect(movie.popularity, 0.0);
    expect(movieYear(movie), '');
    expect(movieMetadata(movie), '');
    expect(movieGenreLabel(movie), '');
  });

  test(
    'null or absent page results are empty when page metadata is present',
    () {
      for (final json in [
        {'page': 1, 'results': null, 'total_pages': 0, 'total_results': 0},
        {'page': 1, 'total_pages': 0, 'total_results': 0},
      ]) {
        final page = TmdbMoviePageDto.fromJson(json);
        expect(page.results, isEmpty);
        expect(page.page, 1);
        expect(page.totalPages, 0);
        expect(page.totalResults, 0);
      }
    },
  );
}
