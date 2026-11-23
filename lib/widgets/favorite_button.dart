import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/favorite_detail_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  Future<void> _toggle(
    BuildContext context,
    FavoriteDetailViewModel model,
  ) async {
    final message = await model.toggle();
    if (!context.mounted ||
        !model.isCurrent ||
        message == null ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FavoriteDetailViewModel?>();
    final auth = context.watch<AuthViewModel>();
    if (auth.status != AuthStatus.signedIn) return const SizedBox.shrink();

    final Widget button;
    if (model == null || !model.isCurrent) {
      button = auth.memberStatus == MemberLoadStatus.error
          ? IconButton.outlined(
              tooltip: '회원 정보 다시 조회',
              onPressed: () => auth.loadMember(force: true),
              icon: const Icon(Icons.refresh),
            )
          : const _FavoriteProgress(label: '회원 정보 조회 중');
    } else if (model.isLoading || model.isSaving) {
      button = _FavoriteProgress(
        label: model.isSaving ? '즐겨찾기 저장 중' : '즐겨찾기 확인 중',
      );
    } else if (!model.hasLoadedStatus) {
      button = IconButton.outlined(
        tooltip: '${model.errorMessage ?? '즐겨찾기 확인'} 다시 시도',
        onPressed: model.load,
        icon: const Icon(Icons.refresh),
      );
    } else {
      button = IconButton.outlined(
        tooltip: model.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 등록',
        isSelected: model.isFavorite,
        onPressed: () => _toggle(context, model),
        icon: const Icon(Icons.bookmark_border),
        selectedIcon: const Icon(Icons.bookmark),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 56, height: 56, child: button),
        const SizedBox(height: 4),
        Text('즐겨찾기', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _FavoriteProgress extends StatelessWidget {
  const _FavoriteProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: label),
    ),
  );
}
