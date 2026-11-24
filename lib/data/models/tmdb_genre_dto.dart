import 'json_values.dart';

class TmdbGenreDto {
  const TmdbGenreDto({required this.id, required this.name});

  final int id;
  final String name;

  factory TmdbGenreDto.fromJson(Map<String, dynamic> json) {
    final id = jsonInt(json['id']);
    if (id <= 0) throw const FormatException('Missing TMDB genre ID.');
    final name = jsonString(json['name']);
    if (name == null) throw const FormatException('Missing TMDB genre name.');
    return TmdbGenreDto(id: id, name: name);
  }
}
