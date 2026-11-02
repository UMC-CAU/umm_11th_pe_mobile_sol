// Read-only integration check: dart run tool/week6_live_check.dart
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';

Future<void> main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final requests = <Map<String, Object?>>[];
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
        requests.add({
          'method': response.requestOptions.method,
          'path': response.requestOptions.path,
          'status': response.statusCode,
          'body': response.data,
        });
        handler.next(response);
      },
      onError: (error, handler) {
        requests.add({
          'method': error.requestOptions.method,
          'path': error.requestOptions.path,
          'status': error.response?.statusCode,
          'body': error.response?.data,
        });
        handler.next(error);
      },
    ),
  );
  try {
    final checks = MemberCheckService(dio);
    final nickname = await checks.checkNickname('sol_week6_check');
    final email = await checks.checkEmail('sol+week6@example.com');
    final ratings = await RatingApiService(dio).fetchMyRatings(1);
    for (final entry in {'not-a-number': 400, '999999999': 404}.entries) {
      try {
        await dio.get<dynamic>('/v5/members/${entry.key}/ratings');
        throw StateError('Expected HTTP ${entry.value}.');
      } on DioException catch (error) {
        if (error.response?.statusCode != entry.value) rethrow;
      }
    }
    final report = {
      'checkedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'readOnly': true,
      'nicknameAvailable': nickname,
      'emailAvailable': email,
      'memberId': 1,
      'ratingCount': ratings.length,
      'requests': requests,
    };
    final file = File('docs/evidence/live-api-checks.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
    );
    stdout.writeln(
      'PASS: v5 nickname/email checks, ${ratings.length} ratings, HTTP 400/404.',
    );
  } finally {
    dio.close(force: true);
  }
}
