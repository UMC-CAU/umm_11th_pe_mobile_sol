import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_colors.dart';
import 'data/models/tmdb_movie_dto.dart';
import 'movie_card.dart';
import 'movie_poster.dart';
import 'view_models/movie_home_view_model.dart';
import 'view_models/movie_request_state.dart';
import 'widgets/movie_metadata.dart';
import 'widgets/movie_states.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('MovieLog'),
      automaticallyImplyLeading: false,
    ),
    body: SafeArea(
      top: false,
      child: Consumer<MovieHomeViewModel>(
        builder: (context, vm, child) {
          if (vm.status == MovieLoadStatus.idle ||
              vm.status == MovieLoadStatus.loading) {
            return const MovieLoadingWidget();
          }
          if (vm.status == MovieLoadStatus.error) {
            return MovieErrorWidget(
              message: vm.errorMessage,
              onRetry: () => context.read<MovieHomeViewModel>().load(),
            );
          }
          if (vm.movies.isEmpty) {
            return const MovieEmptyWidget(message: '지금은 인기 영화가 없어요.');
          }
          final featured = vm.movies.first;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  Text(
                    '오늘은 어떤\n영화를 볼까요?',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),
                  FeaturedMovieCard(
                    movie: featured,
                    onTap: () =>
                        context.push('/movies/${featured.id}', extra: featured),
                  ),
                  const SizedBox(height: 24),
                  SectionHeading(
                    title: '인기 영화',
                    onViewAll: () => context.go('/movies'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height:
                        220 * 1.5 +
                        MediaQuery.textScalerOf(context).scale(16) * 1.4 +
                        MediaQuery.textScalerOf(context).scale(14) * 1.5 +
                        24,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: vm.movies.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final movie = vm.movies[index];
                        return SizedBox(
                          width: 220,
                          child: MovieCard(
                            movie: movie,
                            onTap: () => context.push(
                              '/movies/${movie.id}',
                              extra: movie,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const TmdbAttribution(),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class FeaturedMovieCard extends StatelessWidget {
  const FeaturedMovieCard({
    super.key,
    required this.movie,
    required this.onTap,
  });
  final TmdbMovieDto movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${movie.title} 상세보기',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
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
                        const Chip(
                          label: Text('오늘의 인기 영화'),
                          backgroundColor: AppColors.chipBackground,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          movie.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            movieYear(movie),
                            'TMDB ${movie.voteAverage.toStringAsFixed(1)} / 10',
                          ].where((value) => value.isNotEmpty).join(' · '),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.info),
                            label: const Text('상세보기'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.statisticValue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 52),
                            ),
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

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    required this.onViewAll,
  });
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
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
