import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'data/models/rating_request.dart';
import 'data/services/rating_api_service.dart';
import 'widgets/movielog_button.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.initialScore = 0,
    this.initialComment,
    required this.onSubmit,
  });
  final int initialScore;
  final String? initialComment;
  final Future<void> Function(int score, String? comment) onSubmit;
  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _score = widget.initialScore;
  late final _commentController = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || _score < 1) return;
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      final text = _commentController.text.trim();
      await widget.onSubmit(_score, text.isEmpty ? null : text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = error is RatingWriteException
            ? error.message
            : '저장하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isSubmitting,
    child: AlertDialog(
      title: Text(widget.initialScore == 0 ? '평점 남기기' : '평점 수정하기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('이 영화는 어떠셨나요?\n내 평점은 5점 만점이에요.'),
            const SizedBox(height: 16),
            FittedBox(
              child: RatingBar.builder(
                initialRating: _score.toDouble(),
                minRating: 1,
                allowHalfRating: false,
                ignoreGestures: _isSubmitting,
                itemCount: 5,
                itemSize: 40,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onRatingUpdate: (value) =>
                    setState(() => _score = validateServerScore(value)),
              ),
            ),
            const SizedBox(height: 12),
            Text(_score == 0 ? '별을 눌러 평점을 선택해주세요.' : '$_score점'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('rating-comment'),
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(hintText: '코멘트를 남겨보세요 (선택)'),
            ),
            if (_errorText != null)
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        MovieLogButton(
          label: '취소',
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
        MovieLogButton(
          key: const Key('rating-confirm'),
          label: '확인',
          isLoading: _isSubmitting,
          onPressed: _score > 0 && !_isSubmitting ? _submit : null,
        ),
      ],
    ),
  );
}
