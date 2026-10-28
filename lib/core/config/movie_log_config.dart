import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The MovieLog backend address is independent from TMDB. Leave it empty until
/// an actual backend address is available; the movie browsing screens only use
/// the TMDB client.
abstract final class MovieLogConfig {
  static String get baseUrl => dotenv.isInitialized
      ? (dotenv.env['MOVIELOG_API_BASE_URL'] ?? '').trim()
      : '';
}

class MovieLogConfigurationException implements Exception {
  const MovieLogConfigurationException();
}
