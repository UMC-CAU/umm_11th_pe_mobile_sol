import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../data/models/rating_with_movie.dart';
import '../movie_poster.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movie_states.dart';
import '../widgets/movielog_button.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      centerTitle: true,
      title: const Text('내가 등록한 평점'),
      titleTextStyle: Theme.of(context).textTheme.titleMedium,
      leading: BackButton(
        onPressed: () => context.canPop() ? context.pop() : context.go('/my'),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  '학습용 회원 #$sampleMemberId의 공개 평점입니다.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Consumer<MyRatingsViewModel>(
                  builder: (context, viewModel, child) =>
                      switch (viewModel.status) {
                        MyRatingsLoadStatus.idle ||
                        MyRatingsLoadStatus.loading =>
                          const MovieLoadingWidget(),
                        MyRatingsLoadStatus.error => MovieErrorWidget(
                          message: viewModel.message,
                          onRetry: viewModel.load,
                        ),
                        MyRatingsLoadStatus.empty => Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.rate_review_outlined,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 16),
                                const Text('등록된 평점이 없어요.'),
                                const SizedBox(height: 16),
                                MovieLogButton(
                                  label: '새로고침',
                                  onPressed: viewModel.load,
                                ),
                              ],
                            ),
                          ),
                        ),
                        MyRatingsLoadStatus.success => RefreshIndicator(
                          onRefresh: viewModel.load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            children: [
                              if (viewModel.message != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(viewModel.message!),
                                ),
                              for (final entry in viewModel.ratings)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _RatingCard(entry: entry),
                                ),
                              const TmdbAttribution(),
                            ],
                          ),
                        ),
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

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});
  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final date = rating.createdAt.toLocal();
    final created =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
    final theme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 108,
                child: movie == null
                    ? const MoviePosterPlaceholder()
                    : MoviePoster(movie: movie),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie?.title ?? '영화 정보 없음', style: theme.titleMedium),
                  const SizedBox(height: 4),
                  Text('TMDB ID ${rating.movieId}', style: theme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text('${rating.score} / 5', style: theme.labelLarge),
                    ],
                  ),
                  if (rating.comment != null &&
                      rating.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(rating.comment!),
                  ],
                  const SizedBox(height: 8),
                  Text(created, style: theme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
