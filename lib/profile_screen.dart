import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'common_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              // 화면 가장자리와 내용 사이의 안쪽 여백
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
              child: Column(
                // 주축: 세로 방향으로 위부터 배치
                mainAxisAlignment: MainAxisAlignment.start,
                // 교차축: 가로 방향으로 영역을 채움
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ProfileHeader(
                    name: '무비러버',
                    introduction:
                        '매주 주말엔 영화관으로 출근하는 프로 관람객. '
                        '좋은 영화를 보고 기록하는 것을 좋아합니다.',
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('프로필 수정 기능은 준비 중입니다.')),
                        );
                      },
                      child: const Text('프로필 수정'),
                    ),
                  ),

                  // 통계 영역 바깥의 위아래 여백
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 32),
                    child: const ProfileStats(),
                  ),

                  const GenreSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 1. 프로필 헤더
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.introduction,
  });

  final String name;
  final String introduction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 128,
          height: 128,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.avatarBorder,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: AppColors.chipBackground,
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(name, textAlign: TextAlign.center, style: textTheme.headlineSmall),

        const SizedBox(height: 8),

        Text(
          introduction,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

// 2. 통계 영역
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      // 주축: 가로, 교차축: 세로
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: StatItem(label: '본 영화', value: '342'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: StatItem(label: '평점', value: '4.2'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: StatItem(label: '즐겨찾기', value: '58'),
        ),
      ],
    );
  }
}

// 3. 재사용 가능한 통계 카드
class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      // 카드 테두리와 글자 사이의 안쪽 여백
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, textAlign: TextAlign.center, style: textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(value, style: textTheme.titleLarge),
        ],
      ),
    );
  }
}

// 4. 선호 장르 영역
class GenreSection extends StatelessWidget {
  const GenreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('선호하는 장르', style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: 16),

        // 가로 공간이 부족하면 다음 줄로 배치
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GenreChip(label: '드라마'),
            GenreChip(label: 'SF'),
            GenreChip(label: '애니메이션'),
          ],
        ),
      ],
    );
  }
}

// 5. 재사용 가능한 장르 Chip
class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.chipBackground,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      labelStyle: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: AppColors.statisticValue),
    );
  }
}
