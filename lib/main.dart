import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:go_router/go_router.dart';

import 'profile_screen.dart';
import 'home_screen.dart';
import 'movie_detail_screen.dart';
import 'main_tab_screen.dart';
import 'sign_up_screen.dart';
import 'app_colors.dart';
import 'common_app_bar.dart';

void main() {
  runApp(const MovieLogApp());
}

// 화면 경로. 로그인은 인증 없이 홈으로 이동하는 Mock 동작입니다.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/movies/:movieId',
      builder: (context, state) =>
          MovieDetailScreen(movieId: state.pathParameters['movieId']!),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          MainTabScreen(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/movies',
          builder: (context, state) => const MoviesPlaceholderScreen(),
        ),
        GoRoute(
          path: '/my',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

// 앱 전체 설정
class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      routerConfig: appRouter,
    );
  }
}

// 시작 화면
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const CommonAppBar(title: 'MovieLog'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                // 주축: 세로, 교차축: 가로
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  Text(
                    'FLUTTER 0주차',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),

                  const SizedBox(height: 30),

                  Image.asset(
                    'assets/images/movielog_logo.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: SvgPicture.asset(
                      'assets/icons/error.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    '영화의 순간을\n기록하세요.',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '보고 싶은 영화부터 나만의 평점까지\n한 곳에서 관리해요.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 64),

                  // 시작하기 → 회원가입 화면
                  ElevatedButton(
                    onPressed: () {
                      context.go('/signup');
                    },
                    child: const Text('시작하기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
