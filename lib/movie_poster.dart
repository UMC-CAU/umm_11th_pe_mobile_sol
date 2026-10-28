import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/config/tmdb_config.dart';
import 'data/models/tmdb_movie_dto.dart';

enum PosterDebugMode { normal, missing, failure }

const _posterDebugSetting = String.fromEnvironment(
  'POSTER_TEST_MODE',
  defaultValue: 'normal',
);

PosterDebugMode get configuredPosterDebugMode => switch (_posterDebugSetting) {
  'null' => PosterDebugMode.missing,
  'error' => PosterDebugMode.failure,
  _ => PosterDebugMode.normal,
};

class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.movie});
  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) => TmdbPoster(
    posterPath: movie.posterPath,
    semanticLabel: '${movie.title} 포스터',
  );
}

/// Shared URL assembly, null handling, loading and error placeholders.
class TmdbPoster extends StatelessWidget {
  const TmdbPoster({
    super.key,
    required this.posterPath,
    this.semanticLabel,
    this.debugMode,
  });
  final String? posterPath;
  final String? semanticLabel;
  final PosterDebugMode? debugMode;

  static String? imageUrl(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty || !value.startsWith('/')) return null;
    return '${TmdbConfig.imageBaseUrl}$value';
  }

  @override
  Widget build(BuildContext context) {
    // Force the actual missing-path or Image.network error branch for recording.
    // A regular run uses the API path; release builds ignore the debug mode.
    final mode = kDebugMode
        ? (debugMode ?? configuredPosterDebugMode)
        : PosterDebugMode.normal;
    final path = switch (mode) {
      PosterDebugMode.normal => posterPath,
      PosterDebugMode.missing => null,
      PosterDebugMode.failure => '/__movielog_debug_missing_poster__.jpg',
    };
    final url = imageUrl(path);
    if (url == null) return const MoviePosterPlaceholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const MoviePosterPlaceholder(loading: true),
      errorBuilder: (_, error, stackTrace) => const MoviePosterPlaceholder(),
    );
  }
}

class MoviePosterPlaceholder extends StatelessWidget {
  const MoviePosterPlaceholder({super.key, this.loading = false});
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    label: loading ? '포스터를 불러오는 중' : '포스터 없음',
    child: ColoredBox(
      color: const Color(0xFFE8E3EC),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.movie_outlined,
                color: Color(0xFF6950AD),
                size: 40,
              ),
      ),
    ),
  );
}
