import 'json_values.dart';

class CommonResponse<T> {
  const CommonResponse({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
  });
  final bool isSuccess;
  final String code;
  final String message;
  final T? result;

  factory CommonResponse.fromJson(
    Object? value,
    T Function(Object? value) parseResult,
  ) {
    final json = jsonObject(value);
    if (json['isSuccess'] is! bool ||
        json['code'] is! String ||
        json['message'] is! String) {
      throw const FormatException('Invalid common response.');
    }
    return CommonResponse<T>(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: json['result'] == null ? null : parseResult(json['result']),
    );
  }
}
