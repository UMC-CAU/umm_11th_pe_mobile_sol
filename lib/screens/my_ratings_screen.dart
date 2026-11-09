import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import '../movie_poster.dart';
import '../movie_rating_input.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movie_states.dart';
import '../widgets/movielog_button.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  Future<void> _edit(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment,
        onSubmit: (score, comment) => vm.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 수정했습니다.')));
  }

  Future<void> _delete(BuildContext context, RatingDto rating) async {
    final vm = context.read<MyRatingsViewModel>();
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DeleteDialog(onConfirm: () => vm.deleteRating(rating.ratingId)),
    );
    if (!context.mounted || deleted != true) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('평점을 삭제했습니다.')));
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final vm = context.read<MyRatingsViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('선택한 평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    final failed = await vm.deleteSelectedRatings();
    if (!context.mounted) return;
    final text = failed > 0
        ? '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.'
        : '선택한 평점을 삭제했습니다.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();
    return PopScope(
      canPop: !vm.isDeletingSelected,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('내가 등록한 평점'),
          titleTextStyle: Theme.of(context).textTheme.titleMedium,
          leading: BackButton(
            onPressed: vm.isDeletingSelected
                ? null
                : () => context.canPop() ? context.pop() : context.go('/my'),
          ),
          actions: [
            if (vm.status == MyRatingsLoadStatus.success || vm.isEditing)
              TextButton(
                onPressed: vm.isDeletingSelected
                    ? null
                    : (vm.isEditing ? vm.cancelEditing : vm.startEditing),
                child: Text(vm.isEditing ? '취소' : '편집'),
              ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          vm.isEditing
                              ? '${vm.selectedRatingIds.length}개 선택됨'
                              : '학습용 회원 #${vm.memberId}의 평점입니다.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (vm.refreshWarning != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Text(
                            vm.refreshWarning!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      Expanded(
                        child: switch (vm.status) {
                          MyRatingsLoadStatus.idle ||
                          MyRatingsLoadStatus.loading =>
                            const MovieLoadingWidget(),
                          MyRatingsLoadStatus.error => MovieErrorWidget(
                            message: vm.message,
                            onRetry: vm.load,
                          ),
                          MyRatingsLoadStatus.empty => Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.rate_review_outlined,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('등록된 평점이 없어요.'),
                                  const SizedBox(height: 16),
                                  MovieLogButton(
                                    label: '새로고침',
                                    onPressed: vm.load,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          MyRatingsLoadStatus.success => RefreshIndicator(
                            onRefresh: vm.load,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              children: [
                                if (vm.message != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(vm.message!),
                                  ),
                                for (final entry in vm.ratings)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _RatingCard(
                                      entry: entry,
                                      isEditing: vm.isEditing,
                                      selected: vm.selectedRatingIds.contains(
                                        entry.rating.ratingId,
                                      ),
                                      onSelect: (selected) => vm.selectRating(
                                        entry.rating.ratingId,
                                        selected,
                                      ),
                                      onEdit: () =>
                                          _edit(context, entry.rating),
                                      onDelete: () =>
                                          _delete(context, entry.rating),
                                    ),
                                  ),
                                const TmdbAttribution(),
                              ],
                            ),
                          ),
                        },
                      ),
                      if (vm.isEditing)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: MovieLogButton(
                            label: '선택한 ${vm.selectedRatingIds.length}개 삭제',
                            width: double.infinity,
                            onPressed:
                                vm.selectedRatingIds.isEmpty ||
                                    vm.isDeletingSelected
                                ? null
                                : () => _deleteSelected(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (vm.isDeletingSelected)
              const ModalBarrier(dismissible: false, color: Colors.black45),
            if (vm.isDeletingSelected)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.entry,
    required this.isEditing,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });
  final RatingWithMovie entry;
  final bool isEditing;
  final bool selected;
  final ValueChanged<bool> onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final date = rating.createdAt.toLocal();
    final created =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final theme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 108,
                child: movie == null
                    ? const MoviePosterPlaceholder()
                    : MoviePoster(movie: movie),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie?.title ?? '영화 정보 없음', style: theme.titleMedium),
                  const SizedBox(height: 4),
                  Text('TMDB ID ${rating.movieId}', style: theme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text('${rating.score} / 5', style: theme.labelLarge),
                    ],
                  ),
                  if (rating.comment != null &&
                      rating.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(rating.comment!),
                  ],
                  const SizedBox(height: 8),
                  Text(created, style: theme.bodySmall),
                ],
              ),
            ),
            if (isEditing)
              Checkbox(
                value: selected,
                onChanged: (value) => onSelect(value ?? false),
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '수정',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: '삭제',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.onConfirm});
  final Future<void> Function() onConfirm;
  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  bool _isDeleting = false;
  String? _error;
  Future<void> _confirm() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _error = error is RatingWriteException
            ? error.message
            : '삭제하지 못했습니다. 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isDeleting,
    child: AlertDialog(
      title: const Text('평점을 삭제할까요?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('삭제한 평점은 복구할 수 없습니다.'),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
        ),
        MovieLogButton(
          label: '삭제',
          isLoading: _isDeleting,
          onPressed: _isDeleting ? null : _confirm,
        ),
      ],
    ),
  );
}
