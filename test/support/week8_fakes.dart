import 'package:dio/dio.dart';
import 'package:movielog/core/storage/token_storage.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
class MemoryTokenStorage implements TokenStorage {
  String? token; bool failRead = false, failWrite = false, failDelete = false;
  @override Future<String?> readAccessToken() async { if (failRead) throw StateError('read failed'); return token; }
  @override Future<void> saveAccessToken(String value) async { if (failWrite) throw StateError('write failed'); token = value; }
  @override Future<void> deleteAccessToken() async { if (failDelete) throw StateError('delete failed'); token = null; }
}
AuthViewModel testAuth({bool signedIn = true}) {
  final auth = AuthViewModel(AuthApiService(Dio()), MemberApiService(Dio()), MemoryTokenStorage());
  auth.status = signedIn ? AuthStatus.signedIn : AuthStatus.signedOut;
  if (signedIn) { auth.member = MemberInfo(email: 'test@example.com', nickname: '테스트', createdAt: DateTime(2026, 1, 1)); auth.memberStatus = MemberLoadStatus.success; }
  return auth;
}
