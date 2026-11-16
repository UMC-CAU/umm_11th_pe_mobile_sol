import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The workbook v5 host is independent from TMDB and does not need a token.
abstract final class MovieLogConfig {
  static const workbookBaseUrl = 'https://workbook.devnoco.com';

  static String get baseUrl {
    final configured = dotenv.isInitialized
        ? (dotenv.env['MOVIELOG_API_BASE_URL'] ?? '').trim()
        : '';
    return configured.isEmpty ? workbookBaseUrl : configured;
  }
}

class MovieLogConfigurationException implements Exception {
  const MovieLogConfigurationException();
}
