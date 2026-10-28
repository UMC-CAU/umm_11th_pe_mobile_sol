import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';

// 각 화면 아래에 공통으로 표시되는 탭 바입니다.
class MainTabScreen extends StatelessWidget {
  const MainTabScreen({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = switch (location) {
      '/movies' => 1,
      '/my' => 2,
      _ => 0,
    };

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.chipBackground,
          onDestinationSelected: (index) {
            const locations = ['/home', '/movies', '/my'];
            if (index != selectedIndex) context.go(locations[index]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.movie_outlined),
              selectedIcon: Icon(Icons.movie),
              label: '영화',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }
}
