import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'mock_movies.dart';
import 'movie_poster.dart';
import 'movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openDetail(BuildContext context) {
    context.push('/movies/${featuredMovie.id}');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MovieLog'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Text('오늘은 어떤\n영화를 볼까요?', style: textTheme.headlineLarge),
                const SizedBox(height: 24),
                FeaturedMovieCard(
                  movie: featuredMovie,
                  onTap: () => _openDetail(context),
                ),
                const SizedBox(height: 24),
                SectionHeading(
                  title: '인기 영화',
                  onViewAll: () => context.go('/movies'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220 * 1.5 +
                      MediaQuery.textScalerOf(context).scale(16) * 1.4 +
                      MediaQuery.textScalerOf(context).scale(14) * 1.5 + 22,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: mockMovies.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final movie = mockMovies[index];
                      return SizedBox(
                        width: 220,
                        child: MovieCard(
                          movie: movie,
                          onTap: () => context.push('/movies/${movie.id}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturedMovieCard extends StatelessWidget {
  const FeaturedMovieCard({super.key, required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '${movie.title} 상세보기',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 포스터가 카드의 기본 높이를 결정합니다.
              AspectRatio(
                aspectRatio: 2 / 3,
                child: MoviePoster(movie: movie),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.35, 1],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.statisticValue,
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Text('추천 신작', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(movie.title, style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${movie.genre} · ${movie.minutes}분', style: textTheme.bodyMedium?.copyWith(color: Colors.white)),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onTap,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.statisticValue,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 52),
                              ),
                              icon: const Icon(Icons.info),
                              label: const Text('상세보기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, required this.onViewAll});
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
        TextButton(
          onPressed: onViewAll,
          style: TextButton.styleFrom(
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          child: const Text('전체보기 ›'),
        ),
      ],
    );
  }
}

