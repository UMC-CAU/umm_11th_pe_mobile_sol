import 'package:flutter/material.dart';
import 'mock_movies.dart';

// 참고 이미지 원본을 그대로 두고 포스터 영역만 화면에서 표시합니다.
class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.movie});
  final Movie movie;

  Widget _fallback(BuildContext context, Object error, StackTrace? stackTrace) {
    return const ColoredBox(
      color: Color(0xFF28213E),
      child: Center(child: Icon(Icons.movie_outlined, color: Colors.white, size: 48)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crop = movie.posterCrop;
    if (crop == null) {
      return Image.asset(movie.posterAsset, fit: BoxFit.cover, errorBuilder: _fallback);
    }
    return LayoutBuilder(builder: (context, constraints) {
      final scaleX = constraints.maxWidth / crop.width;
      final scaleY = constraints.maxHeight / crop.height;
      final scale = scaleX > scaleY ? scaleX : scaleY;
      return ClipRect(child: Stack(children: [
        Positioned(
          left: (constraints.maxWidth - crop.width * scale) / 2 - crop.left * scale,
          top: (constraints.maxHeight - crop.height * scale) / 2 - crop.top * scale,
          width: movie.sourceWidth! * scale,
          height: movie.sourceHeight! * scale,
          child: Image.asset(movie.posterAsset,
            fit: BoxFit.fill,
            excludeFromSemantics: true,
            errorBuilder: _fallback,
          ),
        ),
      ]));
    });
  }
}
