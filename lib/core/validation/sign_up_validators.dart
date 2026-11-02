import 'package:flutter/widgets.dart';

abstract final class SignUpValidators {
  static String? nickname(String? value) =>
      (value ?? '').trim().characters.length < 2 ? '닉네임은 2자 이상이어야 합니다.' : null;

  static String? email(String? value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((value ?? '').trim())
      ? null
      : '올바른 이메일 형식이 아닙니다.';

  static String? password(String? value) =>
      (value ?? '').characters.length < 8 ? '비밀번호는 8자 이상이어야 합니다.' : null;
}
