import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_models/auth_view_model.dart';
import 'widgets/movielog_button.dart';
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final retry = auth.status == AuthStatus.retryRequired;
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(children: [const SizedBox(height: 48), Image.asset('assets/images/movielog_logo.png', width: 120, height: 120), const SizedBox(height: 32),
          Text('영화의 순간을\n기록하세요', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16), const Text('보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요', textAlign: TextAlign.center)]),
        if (retry) Column(children: [Text(auth.message ?? '로그인 상태를 확인하지 못했어요.'), const SizedBox(height: 12),
          MovieLogButton(label: '다시 시도', width: double.infinity, onPressed: auth.restoreSession)]) else const CircularProgressIndicator(),
      ])),
    ))));
  }
}
