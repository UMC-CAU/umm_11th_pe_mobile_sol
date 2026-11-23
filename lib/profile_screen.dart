import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import 'view_models/auth_view_model.dart';
import 'widgets/movielog_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          TextButton(
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            child: const Text('로그아웃'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: member == null
                ? auth.memberStatus == MemberLoadStatus.error
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(auth.message ?? '내 정보를 불러오지 못했어요.'),
                            const SizedBox(height: 16),
                            MovieLogButton(
                              label: '다시 시도',
                              onPressed: () => auth.loadMember(force: true),
                            ),
                          ],
                        )
                      : const CircularProgressIndicator()
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 58,
                        backgroundColor: AppColors.chipBackground,
                        child: Icon(
                          Icons.person,
                          size: 68,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        member.nickname,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(member.email, textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(
                        '${member.createdAt.year}.${member.createdAt.month.toString().padLeft(2, '0')}.${member.createdAt.day.toString().padLeft(2, '0')} 가입',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.push('/my/profile/edit'),
                        child: const Text('프로필 수정'),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        color: AppColors.cardBackground,
                        child: ListTile(
                          leading: const Icon(
                            Icons.star_outline,
                            color: AppColors.primary,
                          ),
                          title: const Text('이번 세션의 평점'),
                          subtitle: const Text('현재 로그인에서 등록한 평점'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/my/ratings'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: AppColors.cardBackground,
                        child: ListTile(
                          leading: const Icon(
                            Icons.bookmark_border,
                            color: AppColors.primary,
                          ),
                          title: const Text('내 즐겨찾기'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/my/favorites'),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
