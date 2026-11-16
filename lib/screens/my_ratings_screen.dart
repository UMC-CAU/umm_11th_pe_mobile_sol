import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../data/models/rating_with_movie.dart';
import '../data/services/rating_api_service.dart';
import '../movie_poster.dart';
import '../movie_rating_input.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/movielog_button.dart';
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});
  Future<void> _edit(BuildContext context, RatingWithMovie entry) async {
    final vm = context.read<MyRatingsViewModel>();
    final saved = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => RatingDialog(initialScore: entry.rating.score, initialComment: entry.rating.comment, onSubmit: (score, comment) => vm.updateRating(ratingId: entry.rating.ratingId, score: score, comment: comment)));
    if (context.mounted && saved == true) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('평점을 수정했어요.')));
  }
  Future<void> _delete(BuildContext context, RatingWithMovie entry) async {
    final vm = context.read<MyRatingsViewModel>();
    final deleted = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => _DeleteDialog(onConfirm: () => vm.deleteRating(entry.rating.ratingId)));
    if (context.mounted && deleted == true) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('평점을 삭제했어요.')));
  }
  @override
  Widget build(BuildContext context) {
    final ratings = context.watch<MyRatingsViewModel>().ratings;
    return Scaffold(appBar: AppBar(centerTitle: true, title: const Text('이번 세션의 평점'), leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/my'))),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: Column(children: [
        Padding(padding: const EdgeInsets.all(20), child: Text('이번 로그인 이후 등록한 평점만 표시됩니다. 앱을 다시 시작하면 이전 평점 목록을 불러올 수 없어요.', style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: ratings.isEmpty ? const Center(child: Text('이번 세션에 등록한 평점이 없어요.')) : ListView.separated(
          padding: const EdgeInsets.all(20), itemCount: ratings.length, separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = ratings[index]; final rating = entry.rating;
            return Card(color: AppColors.cardBackground, child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 72, height: 108, child: entry.movie == null ? const MoviePosterPlaceholder() : MoviePoster(movie: entry.movie!)), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.movie?.title ?? '영화 #${rating.movieId}', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text('★ ${rating.score} / 5'), if (rating.comment != null && rating.comment!.isNotEmpty) ...[const SizedBox(height: 8), Text(rating.comment!)]])),
              Column(children: [IconButton(tooltip: '수정', onPressed: () => _edit(context, entry), icon: const Icon(Icons.edit_outlined)), IconButton(tooltip: '삭제', onPressed: () => _delete(context, entry), icon: const Icon(Icons.delete_outline))]),
            ])));
          },
        )),
      ])))));
  }
}
class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.onConfirm});
  final Future<void> Function() onConfirm;
  @override State<_DeleteDialog> createState() => _DeleteDialogState();
}
class _DeleteDialogState extends State<_DeleteDialog> {
  bool _working = false; String? _error;
  Future<void> _confirm() async {
    if (_working) return;
    setState(() { _working = true; _error = null; });
    try { await widget.onConfirm(); if (mounted) Navigator.pop(context, true); }
    catch (error) {
      if (!mounted) return;
      final message = error is RatingWriteException ? error.message : '삭제하지 못했어요. 다시 시도해 주세요.';
      setState(() { _working = false; _error = message; });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
    }
  }
  @override Widget build(BuildContext context) => PopScope(canPop: !_working, child: AlertDialog(title: const Text('평점을 삭제할까요?'), content: Text(_error ?? '삭제한 평점은 복구할 수 없어요.'), actions: [
    MovieLogButton(label: '취소', onPressed: _working ? null : () => Navigator.pop(context, false)),
    MovieLogButton(label: '삭제', isLoading: _working, onPressed: _working ? null : _confirm),
  ]));
}
