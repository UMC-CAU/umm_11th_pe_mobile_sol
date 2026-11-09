import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'movie_poster.dart';
import 'movie_rating_input.dart';
import 'view_models/movie_detail_view_model.dart';
import 'view_models/movie_request_state.dart';
import 'widgets/movie_metadata.dart';
import 'widgets/movie_states.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _favorite = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _rate() async {
    final vm = context.read<MovieDetailViewModel>();
    if (vm.movie == null) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) =>
            vm.createRating(score: score, comment: comment),
      ),
    );
    if (!mounted || saved != true) return;
    _notify('평점을 등록했습니다. 마이페이지의 내가 등록한 평점에서 확인할 수 있습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MovieDetailViewModel>();
    final movie = vm.movie;
    final theme = Theme.of(context);
    final hasPrevious = context.canPop();
    return PopScope(
      canPop: hasPrevious,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('영화 상세'),
          centerTitle: true,
          leading: IconButton(
            tooltip: '뒤로 가기',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            if (movie != null)
              IconButton(
                tooltip: '영화 정보 복사',
                icon: const Icon(Icons.copy_outlined),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: '${movie.title}\n${movieMetadata(movie)}',
                    ),
                  );
                  if (mounted) _notify('영화 정보를 복사했어요.');
                },
              ),
          ],
        ),
        body: movie == null
            ? vm.status == MovieLoadStatus.loading ||
                      vm.status == MovieLoadStatus.idle
                  ? const MovieLoadingWidget()
                  : MovieErrorWidget(
                      message: vm.errorMessage,
                      onRetry: () =>
                          context.read<MovieDetailViewModel>().load(),
                    )
            : SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      children: [
                        if (vm.status == MovieLoadStatus.loading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (vm.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(vm.errorMessage!),
                                TextButton(
                                  onPressed: () => context
                                      .read<MovieDetailViewModel>()
                                      .load(),
                                  child: const Text('상세 정보 다시 불러오기'),
                                ),
                              ],
                            ),
                          ),
                        AspectRatio(
                          aspectRatio: 2 / 3,
                          child: MoviePoster(movie: movie),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: theme.textTheme.headlineLarge,
                              ),
                              const SizedBox(height: 8),
                              if (movieMetadata(movie).isNotEmpty)
                                Text(movieMetadata(movie)),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: theme.colorScheme.primary,
                                  ),
                                  Text(
                                    'TMDB ${movie.voteAverage.toStringAsFixed(1)} / 10',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  Text('평가 ${movie.voteCount}개'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  for (final genre in movie.genres)
                                    Chip(label: Text(genre.name)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('시놉시스', style: theme.textTheme.titleLarge),
                              const SizedBox(height: 12),
                              if (movie.overview.trim().isEmpty)
                                const SizedBox(
                                  width: double.infinity,
                                  height: 120,
                                  child: Center(child: Text('줄거리 정보가 없어요.')),
                                )
                              else
                                Text(
                                  movie.overview,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 16,
                                    height: 1.8,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const TmdbAttribution(),
                      ],
                    ),
                  ),
                ),
              ),
        bottomNavigationBar: movie == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _favorite = !_favorite);
                          _notify(
                            _favorite ? '이 화면에서 즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.',
                          );
                        },
                        icon: Icon(
                          _favorite ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        label: Text(_favorite ? '즐겨찾기 해제' : '즐겨찾기'),
                      ),
                      if (vm.memberId == null)
                        const Text('평점을 남기려면 학습용 회원가입이 필요합니다.'),
                      FilledButton.icon(
                        onPressed: vm.memberId == null ? null : _rate,
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('평점 남기기'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
