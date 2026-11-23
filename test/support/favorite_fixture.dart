import 'dart:async';

import 'package:movielog/data/models/favorite_check_dto.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/services/favorite_api_service.dart';

FavoriteResponseDto favoriteForMovie(int movieId) => FavoriteResponseDto(
  favoriteId: movieId + 1000,
  movieId: movieId,
  createdAt: DateTime.utc(2026, 11, 20),
);

class FavoriteFixture implements FavoriteApiService {
  FavoriteFixture(this.ids);

  final Set<int> ids;
  final statusReads = <int>[];
  final additions = <int>[];
  final removals = <int>[];
  FutureOr<List<FavoriteResponseDto>?> Function()? readList;
  FutureOr<void> Function(int)? beforeAdd;
  FutureOr<void> Function(int)? beforeRemove;

  @override
  Future<FavoriteResponseDto> add(int movieId) async {
    additions.add(movieId);
    await beforeAdd?.call(movieId);
    ids.add(movieId);
    return favoriteForMovie(movieId);
  }

  @override
  Future<List<FavoriteResponseDto>> fetchMyFavorites() async =>
      (await readList?.call()) ?? ids.map(favoriteForMovie).toList();

  @override
  Future<FavoriteCheckDto> getStatus(int movieId) async {
    statusReads.add(movieId);
    return FavoriteCheckDto(
      movieId: movieId,
      isFavorite: ids.contains(movieId),
    );
  }

  @override
  Future<void> remove(int movieId) async {
    removals.add(movieId);
    await beforeRemove?.call(movieId);
    ids.remove(movieId);
  }
}
