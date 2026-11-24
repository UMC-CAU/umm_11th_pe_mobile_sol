import 'json_values.dart';

class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });

  final int favoriteId;
  final int movieId;
  final DateTime createdAt;

  factory FavoriteResponseDto.fromJson(Map<String, dynamic> json) {
    final favoriteId = jsonInt(json['favoriteId']);
    final movieId = jsonInt(json['movieId']);
    final createdAt = DateTime.tryParse(jsonString(json['createdAt']) ?? '');
    if (favoriteId <= 0 || movieId <= 0 || createdAt == null) {
      throw const FormatException('Invalid favorite response.');
    }
    return FavoriteResponseDto(
      favoriteId: favoriteId,
      movieId: movieId,
      createdAt: createdAt,
    );
  }
}
