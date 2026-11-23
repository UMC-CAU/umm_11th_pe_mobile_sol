import 'package:flutter/material.dart';

import 'movielog_button.dart';

class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({
    super.key,
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
    this.errorMessage,
    this.label = '더 보기',
  });

  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;
  final String? errorMessage;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    child: hasMore
        ? Column(
            children: [
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(errorMessage!, textAlign: TextAlign.center),
                ),
              Semantics(
                label: isLoading ? '다음 페이지를 불러오는 중' : null,
                child: MovieLogButton(
                  label: errorMessage == null ? label : '다음 페이지 다시 시도',
                  width: double.infinity,
                  isLoading: isLoading,
                  onPressed: onLoadMore,
                ),
              ),
            ],
          )
        : const Text('모든 영화를 확인했어요.', textAlign: TextAlign.center),
  );
}
