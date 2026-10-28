import 'package:shared_preferences/shared_preferences.dart';

import '../models/tmdb_genre_dto.dart';

abstract interface class MovieGenrePreferences {
  Future<List<int>> read(List<TmdbGenreDto> genres);
  Future<void> write(List<int> ids, List<TmdbGenreDto> genres);
}

class SharedMovieGenrePreferences implements MovieGenrePreferences {
  SharedMovieGenrePreferences({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const idsKey = 'last_selected_movie_genre_ids';
  static const legacyKey = 'last_selected_movie_genre';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<int>> read(List<TmdbGenreDto> genres) async {
    final saved = await _preferences.getStringList(idsKey);
    if (saved != null) return saved.map(int.tryParse).whereType<int>().toList();

    // Preserve week 4's saved genre name during the first upgrade to TMDB IDs.
    final oldName = await _preferences.getString(legacyKey);
    return [
      for (final genre in genres)
        if (genre.name == oldName) genre.id,
    ];
  }

  @override
  Future<void> write(List<int> ids, List<TmdbGenreDto> genres) async {
    await _preferences.setStringList(idsKey, ids.map((id) => '$id').toList());
    final names = genres
        .where((genre) => ids.contains(genre.id))
        .map((genre) => genre.name);
    await _preferences.setString(
      legacyKey,
      ids.isEmpty ? '전체' : names.join(' | '),
    );
  }
}
