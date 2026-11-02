// flutter run -t tool/week6_buttons.dart
import 'package:flutter/material.dart';
import 'package:movielog/app_colors.dart';
import 'package:movielog/widgets/movielog_button.dart';

void main() => runApp(const ButtonPreviewApp());

class ButtonPreviewApp extends StatelessWidget {
  const ButtonPreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    ),
    home: Scaffold(
      appBar: AppBar(title: const Text('MovieLogButton · 너비와 상태')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('width: null · 내용에 맞게'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: MovieLogButton(label: '중복 확인', onPressed: () {}),
              ),
              const SizedBox(height: 24),
              const Text('width: double.infinity · 부모의 최대 너비'),
              const SizedBox(height: 8),
              MovieLogButton(
                label: '가입하기',
                width: double.infinity,
                onPressed: () {},
              ),
              const SizedBox(height: 24),
              const Text('width: 96 · 고정 너비'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: MovieLogButton(label: '확인', width: 96, onPressed: () {}),
              ),
              const SizedBox(height: 32),
              const Text('통신 중 · 회색 + 인디케이터'),
              const SizedBox(height: 8),
              MovieLogButton(
                label: '확인',
                width: double.infinity,
                isLoading: true,
                onPressed: () {},
              ),
              const SizedBox(height: 24),
              const Text('비활성 · onPressed: null'),
              const SizedBox(height: 8),
              const MovieLogButton(
                label: '가입하기',
                width: double.infinity,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
