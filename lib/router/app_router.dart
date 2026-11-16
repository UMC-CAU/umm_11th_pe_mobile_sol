import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/local/movie_genre_preferences.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../home_screen.dart';
import '../main_tab_screen.dart';
import '../movie_detail_screen.dart';
import '../movies_screen.dart';
import '../profile_screen.dart';
import '../sign_up_screen.dart';
import '../start_screen.dart';
import '../screens/login_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
String? authRedirect(AuthStatus status, String location) {
  final isStart = location == '/'; final isPublic = location == '/login' || location == '/signup';
  return switch (status) {
    AuthStatus.initializing || AuthStatus.retryRequired => isStart ? null : '/',
    AuthStatus.signedOut || AuthStatus.authenticating => isPublic ? null : '/login',
    AuthStatus.signedIn => (isStart || isPublic) ? '/home' : null,
  };
}
GoRouter createAppRouter({String initialLocation = '/', required AuthViewModel auth}) {
  final root = GlobalKey<NavigatorState>();
  return GoRouter(initialLocation: initialLocation, navigatorKey: root, refreshListenable: auth, redirect: (_, state) => authRedirect(auth.status, state.uri.path), routes: [
    GoRoute(path: '/', builder: (_, _) => const StartScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(create: (context) => SignUpViewModel(context.read<SignUpService>()), child: const SignUpScreen())),
    GoRoute(path: '/movies/:movieId', builder: (context, state) => ChangeNotifierProvider<MovieDetailViewModel>(key: ValueKey(state.uri.path), create: (context) => MovieDetailViewModel(
      context.read<TmdbMovieService>(), ratingService: context.read<RatingApiService>(), auth: context.read<AuthViewModel>(), sessionRatings: context.read<SessionRatings>(), movieId: int.tryParse(state.pathParameters['movieId'] ?? ''), initialMovie: state.extra is TmdbMovieDto ? state.extra as TmdbMovieDto : null,
    )..load(), child: const MovieDetailScreen())),
    ShellRoute(builder: (context, state, child) => MainTabScreen(location: state.uri.path, child: child), routes: [
      GoRoute(path: '/home', builder: (context, state) => ChangeNotifierProvider<MovieHomeViewModel>(create: (context) => MovieHomeViewModel(context.read<TmdbMovieService>())..load(), child: const HomeScreen())),
      GoRoute(path: '/movies', builder: (context, state) {
        final rawIds = state.uri.queryParameters['genreIds'];
        return ChangeNotifierProvider<MovieListViewModel>(key: ValueKey(state.uri.toString()), create: (context) => MovieListViewModel(context.read<TmdbMovieService>(), context.read<MovieGenrePreferences>(), initialGenreIds: rawIds?.split(RegExp(r'[|,]')).map(int.tryParse).whereType<int>().toList(), initialGenreName: state.uri.queryParameters['genre'])..load(), child: const MoviesScreen());
      }),
      GoRoute(path: '/my', builder: (context, state) => const ProfileScreen(), routes: [
        GoRoute(path: 'ratings', parentNavigatorKey: root, builder: (context, state) => ChangeNotifierProvider<MyRatingsViewModel>(create: (context) => MyRatingsViewModel(context.read<RatingApiService>(), context.read<SessionRatings>(), context.read<AuthViewModel>()), child: const MyRatingsScreen())),
        GoRoute(path: 'profile/edit', parentNavigatorKey: root, builder: (context, state) {
          final model = context.watch<AuthViewModel>();
          if (model.member == null) return Scaffold(appBar: AppBar(title: const Text('프로필 수정')), body: Center(child: model.memberStatus == MemberLoadStatus.error ? TextButton(onPressed: () => model.loadMember(force: true), child: const Text('다시 시도')) : const CircularProgressIndicator()));
          return const EditProfileScreen();
        }),
      ]),
    ]),
  ], errorBuilder: (context, state) => Scaffold(appBar: AppBar(title: const Text('MovieLog')), body: Center(child: FilledButton(onPressed: () => context.go('/home'), child: const Text('홈으로 이동')))));
}
