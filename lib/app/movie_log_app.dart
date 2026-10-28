import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/local/movie_genre_preferences.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({
    super.key,
    this.initialLocation = '/',
    this.movieService,
    this.genrePreferences,
  });
  final String initialLocation;
  final TmdbMovieService? movieService;
  final MovieGenrePreferences? genrePreferences;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final GoRouter _router = createAppRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<TmdbClient>(
        create: (_) => TmdbClient(),
        dispose: (_, client) => client.close(),
      ),
      Provider<MovieLogClient>(
        create: (_) => MovieLogClient(),
        dispose: (_, client) => client.close(),
      ),
      Provider<TmdbMovieService>(
        create: (context) =>
            widget.movieService ??
            TmdbMovieService(context.read<TmdbClient>().dio),
      ),
      Provider<MovieGenrePreferences>(
        create: (_) => widget.genrePreferences ?? SharedMovieGenrePreferences(),
      ),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Manrope',
        scaffoldBackgroundColor: AppColors.background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
        ),

        // 공통 글자 스타일
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            height: 1.4,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 26,
            height: 1.4,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.statisticValue,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          titleTextStyle: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      routerConfig: _router,
    ),
  );
}
