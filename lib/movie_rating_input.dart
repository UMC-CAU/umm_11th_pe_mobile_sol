import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'data/models/movie_rating_draft.dart';

class MovieRatingInput extends StatefulWidget {
  const MovieRatingInput({
    super.key,
    required this.movieId,
    this.initialRating = 0,
  });
  final int movieId;
  final double initialRating;
  @override
  State<MovieRatingInput> createState() => _MovieRatingInputState();
}

class _MovieRatingInputState extends State<MovieRatingInput> {
  late double _rating = widget.initialRating;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('평점 남기기'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('이 영화는 어떠셨나요?\n내 평점은 5점 만점이에요.'),
          const SizedBox(height: 20),
          FittedBox(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 0.5,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (context, index) => Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.primary,
              ),
              onRatingUpdate: (rating) => setState(() => _rating = rating),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _rating == 0
                ? '별을 눌러 평점을 선택해주세요.'
                : '${_rating.toStringAsFixed(1)}점',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: _rating == 0
            ? null
            : () => Navigator.of(
                context,
              ).pop(MovieRatingDraft(movieId: widget.movieId, score: _rating)),
        child: const Text('저장'),
      ),
    ],
  );
}
