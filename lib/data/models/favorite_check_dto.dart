class FavoriteCheckDto {
  const FavoriteCheckDto({required this.movieId, required this.isFavorite});

  final int movieId;
  final bool isFavorite;

  factory FavoriteCheckDto.fromJson(
    Map<String, dynamic> json, {
    required int movieId,
  }) {
    final isFavorite = json['isFavorite'];
    if (isFavorite is! bool) {
      throw const FormatException('Invalid favorite status.');
    }
    return FavoriteCheckDto(movieId: movieId, isFavorite: isFavorite);
  }
}
