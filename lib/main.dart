import 'package:flutter/material.dart';

void main() {
  runApp(const MovieLogApp());
}

// lib/movie_log_app.dart
class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: ThemeData(useMaterial3: true),
      home: const StartScreen(), // 첫 실행 화면 지정
    );
  }
}

// lib/start_screen.dart
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 75),

            const Text(
              'FLUTTER 0주차',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const Icon(
              Icons.movie_outlined,
              size: 72,
              color: Colors.deepPurple,
            ),

            const SizedBox(height: 30),

            const Text(
              '영화의 순간을\n기록하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              '보고 싶은 영화부터 나만의 평점까지\n한 곳에서 관리해요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 250),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('시작하기 버튼을 눌렀습니다.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5545A5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('시작하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
