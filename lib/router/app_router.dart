import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/local/movie_genre_preferences.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/services/sign_up_service.dart';
import '../view_models/learning_member_session.dart';
import '../data/services/rating_api_service.dart';
import '../home_screen.dart';
import '../main_tab_screen.dart';
import '../movie_detail_screen.dart';
import '../movies_screen.dart';
import '../profile_screen.dart';
import '../sign_up_screen.dart';
import '../start_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';

GoRouter createAppRouter({String initialLocation = '/'}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    initialLocation: initialLocation,
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) => SignUpViewModel(context.read<SignUpService>()),
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) =>
            ChangeNotifierProvider<MovieDetailViewModel>(
              key: ValueKey(state.uri.path),
              create: (context) => MovieDetailViewModel(
                context.read<TmdbMovieService>(),
                ratingService: context.read<RatingApiService>(),
                memberId: context.read<LearningMemberSession>().memberId,
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
            routes: [
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final id = context.read<LearningMemberSession>().memberId;
                  if (id == null) {
                    return Scaffold(
                      appBar: AppBar(
                        centerTitle: true,
                        title: const Text('내가 등록한 평점'),
                      ),
                      body: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('학습용 회원가입이 필요합니다.'),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => context.go('/signup'),
                              child: const Text('회원가입'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ChangeNotifierProvider<MyRatingsViewModel>(
                    create: (context) => MyRatingsViewModel(
                      context.read<RatingApiService>(),
                      context.read<TmdbMovieService>(),
                      id,
                    )..load(),
                    child: const MyRatingsScreen(),
                  );
                },
              ),
            ],
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
}
