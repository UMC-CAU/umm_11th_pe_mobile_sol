import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/storage/token_storage.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings.dart';
import '../data/local/movie_genre_preferences.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({
    super.key,
    this.initialLocation = '/',
    this.movieService,
    this.genrePreferences,
    this.memberCheckService,
    this.ratingApiService,
    this.authViewModel,
    this.tokenStorage,
  });
  final String initialLocation;
  final TmdbMovieService? movieService;
  final MovieGenrePreferences? genrePreferences;
  final SignUpService? memberCheckService;
  final RatingApiService? ratingApiService;
  final AuthViewModel? authViewModel;
  final TokenStorage? tokenStorage;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final TokenStorage _storage;
  late final MovieLogClient _publicClient;
  late final ProtectedMovieLogClient _protectedClient;
  late final TmdbClient _tmdbClient;
  late final AuthViewModel _auth;
  late final SessionRatings _sessionRatings;
  late final MemberApiService _memberApi;
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    _storage = widget.tokenStorage ?? SecureTokenStorage();
    _publicClient = MovieLogClient();
    _protectedClient = ProtectedMovieLogClient(storage: _storage, sessionVersion: () => _auth.sessionVersion, expireSession: (version) => _auth.expireSession(version));
    _tmdbClient = TmdbClient();
    _memberApi = MemberApiService(_protectedClient.dio);
    _auth = widget.authViewModel ?? AuthViewModel(AuthApiService(_publicClient.dio), _memberApi, _storage);
    _sessionRatings = SessionRatings(_auth);
    _router = createAppRouter(initialLocation: widget.initialLocation, auth: _auth);
    if (widget.authViewModel == null) _auth.restoreSession();
  }
  @override
  void dispose() {
    _router.dispose(); _sessionRatings.dispose();
    if (widget.authViewModel == null) _auth.dispose();
    _publicClient.close(); _protectedClient.close(); _tmdbClient.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => MultiProvider(providers: [
      ChangeNotifierProvider<AuthViewModel>.value(value: _auth),
      ChangeNotifierProvider<SessionRatings>.value(value: _sessionRatings),
      Provider<TokenStorage>.value(value: _storage),
      Provider<MovieLogClient>.value(value: _publicClient),
      Provider<ProtectedMovieLogClient>.value(value: _protectedClient),
      Provider<TmdbClient>.value(value: _tmdbClient),
      Provider<MemberApiService>.value(value: _memberApi),
      Provider<TmdbMovieService>(create: (_) => widget.movieService ?? TmdbMovieService(_tmdbClient.dio)),
      Provider<SignUpService>(create: (_) => widget.memberCheckService ?? SignUpService(_publicClient.dio)),
      Provider<RatingApiService>(create: (_) => widget.ratingApiService ?? RatingApiService(_publicClient.dio, _protectedClient.dio)),
      Provider<MovieGenrePreferences>(create: (_) => widget.genrePreferences ?? SharedMovieGenrePreferences()),
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
