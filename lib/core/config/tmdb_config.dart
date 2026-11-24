import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class TmdbConfig {
  static const baseUrl = 'https://api.themoviedb.org/3';
  static const imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  static const language = 'ko-KR';

  static String get accessToken => dotenv.isInitialized
      ? (dotenv.env['TMDB_ACCESS_TOKEN'] ?? '').trim()
      : '';
}

class TmdbConfigurationException implements Exception {
  const TmdbConfigurationException();
}
