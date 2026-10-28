import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'common_app_bar.dart';

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
                    'MovieLog',
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
