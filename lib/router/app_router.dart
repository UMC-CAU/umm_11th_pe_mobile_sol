import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/local/movie_genre_preferences.dart';
import '../data/services/tmdb_movie_service.dart';
import '../home_screen.dart';
import '../main_tab_screen.dart';
import '../movie_detail_screen.dart';
import '../movies_screen.dart';
import '../profile_screen.dart';
import '../sign_up_screen.dart';
import '../start_screen.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';

GoRouter createAppRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/movies/:movieId',
      builder: (context, state) => ChangeNotifierProvider<MovieDetailViewModel>(
        key: ValueKey(state.uri.path),
        create: (context) => MovieDetailViewModel(
          context.read<TmdbMovieService>(),
          movieId: int.tryParse(state.pathParameters['movieId'] ?? ''),
          initialMovie: state.extra is TmdbMovieDto
              ? state.extra as TmdbMovieDto
              : null,
        )..load(),
        child: const MovieDetailScreen(),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          MainTabScreen(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              ChangeNotifierProvider<MovieHomeViewModel>(
                create: (context) =>
                    MovieHomeViewModel(context.read<TmdbMovieService>())
                      ..load(),
                child: const HomeScreen(),
              ),
        ),
        GoRoute(
          path: '/movies',
          builder: (context, state) {
            final rawIds = state.uri.queryParameters['genreIds'];
            return ChangeNotifierProvider<MovieListViewModel>(
              key: ValueKey(state.uri.toString()),
              create: (context) => MovieListViewModel(
                context.read<TmdbMovieService>(),
                context.read<MovieGenrePreferences>(),
                initialGenreIds: rawIds
                    ?.split(RegExp(r'[|,]'))
                    .map(int.tryParse)
                    .whereType<int>()
                    .toList(),
                initialGenreName: state.uri.queryParameters['genre'],
              )..load(),
              child: const MoviesScreen(),
            );
          },
        ),
        GoRoute(
          path: '/my',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('MovieLog')),
    body: Center(
      child: FilledButton(
        onPressed: () => context.go('/home'),
        child: const Text('홈으로 이동'),
      ),
    ),
  ),
);
