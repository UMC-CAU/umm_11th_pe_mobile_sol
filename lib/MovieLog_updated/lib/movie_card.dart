import 'package:flutter/material.dart';
import 'mock_movies.dart';
import 'movie_poster.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, required this.onTap});
  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${movie.title}, 평점 ${movie.rating}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(fit: StackFit.expand, children: [
                MoviePoster(movie: movie),
                Positioned(top: 8, right: 8, child: MovieRatingBadge(rating: movie.rating)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text('${movie.year} · ${movie.genres.contains('드라마') ? '드라마' : movie.genres.first}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14)),
        ]),
      ),
    );
  }
}

class MovieRatingBadge extends StatelessWidget {
  const MovieRatingBadge({super.key, required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6555358),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text('★ ${rating.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
