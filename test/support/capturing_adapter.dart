import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class CapturingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = {
    'page': 1,
    'results': [],
    'total_pages': 0,
    'total_results': 0,
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
