import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'mock_movies.dart';
import 'movie_poster.dart';
import 'movie_rating_input.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.initialMovie});
  final Movie? initialMovie;
  final String movieId;
  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _favorite = false;
  double? _myRating;

  @override
  void didUpdateWidget(covariant MovieDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != widget.movieId) {
      _favorite = false;
      _myRating = null;
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      // 상세 URL로 바로 실행한 경우에도 나갈 수 있습니다.
      context.go('/home');
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _rate() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (_) => MovieRatingInput(initialRating: _myRating ?? 0),
    );
    if (!mounted || rating == null) return;
    setState(() => _myRating = rating);
    _notify('${rating.toStringAsFixed(1)}점으로 평점을 남겼어요.');
  }

  @override
  Widget build(BuildContext context) {
    // Extra가 없거나 경로 ID와 다르면 공통 Mock 목록에서 다시 찾습니다.
    final passedMovie = widget.initialMovie;
    final movie = passedMovie != null && passedMovie.id == widget.movieId
        ? passedMovie
        : findMovieById(widget.movieId);
    final theme = Theme.of(context);
    final hasPrevious = context.canPop();
    return PopScope(
      canPop: hasPrevious,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cinema Archive'), centerTitle: true,
          leading: IconButton(tooltip: '뒤로 가기', onPressed: _back, icon: const Icon(Icons.arrow_back)),
          actions: [if (movie != null) IconButton(
            tooltip: '영화 정보 복사', icon: const Icon(Icons.copy_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: '${movie.title}\n${movie.metadata}'));
              if (!mounted) return;
              _notify('영화 정보를 복사했어요.');
            },
          )],
        ),
        body: movie == null
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('영화를 찾을 수 없어요.'),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.go('/movies'), child: const Text('영화 목록으로')),
              ]))
            : SafeArea(top: false, child: Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(children: [
                  AspectRatio(aspectRatio: 2 / 3,
                    child: MoviePoster(movie: movie),
                  ),
                  Padding(padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(movie.title, style: theme.textTheme.headlineLarge),
                      const SizedBox(height: 8),
                      Text(movie.metadata),
                      const SizedBox(height: 20),
                      Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Semantics(label: '평균 평점 ${movie.rating}점, 읽기 전용',
                          child: RatingBarIndicator(
                            rating: movie.rating, itemCount: 5, itemSize: 26,
                            itemBuilder: (_, index) => Icon(Icons.star, color: theme.colorScheme.primary),
                          ),
                        ),
                        Text('${movie.rating.toStringAsFixed(1)} (${movie.ratingCount})', style: theme.textTheme.titleMedium),
                      ]),
                      if (_myRating != null) Padding(padding: const EdgeInsets.only(top: 12),
                        child: Text('내 평점 ${_myRating!.toStringAsFixed(1)}점',
                          style: TextStyle(color: theme.colorScheme.primary)),
                      ),
                      const SizedBox(height: 20),
                      Wrap(spacing: 8, runSpacing: 4, children: [
                        for (final genre in movie.tags) Chip(label: Text(genre)),
                      ]),
                    ]),
                  ),
                  const Divider(height: 1),
                  Padding(padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('시놉시스', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text(movie.synopsis, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.8)),
                    ]),
                  ),
                ]),
              ))),
        bottomNavigationBar: movie == null ? null : SafeArea(
          child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _favorite = !_favorite);
                  _notify(_favorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.');
                },
                icon: Icon(_favorite ? Icons.bookmark : Icons.bookmark_border),
                label: Text(_favorite ? '즐겨찾기 해제' : '즐겨찾기'),
              ),
              FilledButton.icon(onPressed: _rate,
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(_myRating == null ? '평점 남기기' : '평점 수정하기'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

