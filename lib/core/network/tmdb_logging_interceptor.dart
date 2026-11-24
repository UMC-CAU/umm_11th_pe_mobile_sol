import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Every path (including errors) uses the same redaction. Request objects are
/// never mutated, and release builds never call the log sink.
class TmdbLoggingInterceptor extends Interceptor {
  TmdbLoggingInterceptor({
    required this.accessToken,
    this.enabled = true,
    void Function(String)? log,
  }) : _log = log ?? debugPrint;

  final String accessToken;
  final bool enabled;
  final void Function(String) _log;

  bool _isSecret(String key) => RegExp(
    r'authorization|api[_-]?key|token|password|secret|cookie',
    caseSensitive: false,
  ).hasMatch(key);

  String _redactText(String value) {
    var safe = value;
    if (accessToken.isNotEmpty) {
      safe = safe.replaceAll(accessToken, '[REDACTED]');
      safe = safe.replaceAll(Uri.encodeComponent(accessToken), '[REDACTED]');
    }
    return safe
        .replaceAll(
          RegExp(r'Bearer\s+[^\s,;"\x27]+', caseSensitive: false),
          'Bearer [REDACTED]',
        )
        .replaceAllMapped(
          RegExp(
            r'((?:access_token|api_key|token)=)[^&\s]+',
            caseSensitive: false,
          ),
          (match) => '${match[1]}[REDACTED]',
        );
  }

  Object? _redact(Object? value) {
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          _isSecret(key.toString()) ? '[REDACTED]' : _redact(item),
        ),
      );
    }
    if (value is Iterable) return value.map(_redact).toList();
    return value is String ? _redactText(value) : value;
  }

  String _url(RequestOptions request) {
    final uri = request.uri;
    return _redactText(
      uri
          .replace(
            queryParameters: {
              for (final entry in uri.queryParameters.entries)
                entry.key: _isSecret(entry.key) ? '[REDACTED]' : entry.value,
            },
          )
          .toString(),
    );
  }

  void _write(String event, Map<String, Object?> data) {
    if (!kDebugMode || !enabled) return;
    _log('[TMDB][$event] ${jsonEncode(_redact(data))}');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _write('REQUEST', {
      'method': options.method,
      'url': _url(options),
      'query': options.queryParameters,
      'headers': options.headers,
    });
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _write('RESPONSE', {
      'url': _url(response.requestOptions),
      'status': response.statusCode,
      'body': response.data,
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _write('ERROR', {
      'method': err.requestOptions.method,
      'url': _url(err.requestOptions),
      'query': err.requestOptions.queryParameters,
      'status': err.response?.statusCode,
      'message': err.message ?? err.type.name,
      'body': err.response?.data,
    });
    handler.next(err);
  }
}
