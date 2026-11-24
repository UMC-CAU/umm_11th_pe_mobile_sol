import 'package:flutter/material.dart';

import 'data/models/tmdb_genre_dto.dart';
import 'data/models/tmdb_movie_dto.dart';
import 'movie_poster.dart';
import 'widgets/movie_metadata.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.genres = const [],
  }) : _compact = false,
       _action = null;

  const MovieCard.compact({
    super.key,
    required this.movie,
    required this.onTap,
    this.genres = const [],
    Widget? action,
  }) : _compact = true,
       _action = action;

  final TmdbMovieDto movie;
  final VoidCallback onTap;
  final List<TmdbGenreDto> genres;
  final bool _compact;
  final Widget? _action;

  @override
  Widget build(BuildContext context) {
    final genre = movieGenreLabel(movie, genres);
    final metadata = [
      movieYear(movie),
      genre,
    ].where((value) => value.isNotEmpty).join(' · ');
    if (_compact) {
      return MovieCardRow(
        title: movie.title,
        subtitle: metadata,
        poster: MoviePoster(movie: movie),
        onTap: onTap,
        action: _action,
      );
    }
    return Semantics(
      button: true,
      label:
          '${movie.title}, TMDB 평점 ${movie.voteAverage.toStringAsFixed(1)}점, 10점 만점',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MoviePoster(movie: movie),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: MovieRatingBadge(rating: movie.voteAverage),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                metadata,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MovieCardRow extends StatelessWidget {
  const MovieCardRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.poster,
    required this.onTap,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget poster;
  final VoidCallback onTap;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 108,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: poster,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (action != null) action!,
                ],
              ),
            ),
            if (action == null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class MovieRatingBadge extends StatelessWidget {
  const MovieRatingBadge({super.key, required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xE6555358),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        '★ ${rating.toStringAsFixed(1)}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}
