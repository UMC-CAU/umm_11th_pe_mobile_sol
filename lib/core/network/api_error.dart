import 'package:dio/dio.dart';
String? apiErrorCode(DioException error) {
  final data = error.response?.data;
  return data is Map && data['code'] is String ? data['code'] as String : null;
}
String? apiErrorMessage(DioException error) {
  final data = error.response?.data;
  return data is Map && data['message'] is String ? data['message'] as String : null;
}
bool isExpiredSessionCode(String? code) => code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
