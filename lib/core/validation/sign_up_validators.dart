import 'package:flutter/widgets.dart';

abstract final class SignUpValidators {
  static String? nickname(String? value) {
    final length = (value ?? '').trim().characters.length;
    if (length < 2 || length > 12) return '닉네임은 2~12자여야 합니다.';
    return null;
  }

  static String? email(String? value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((value ?? '').trim())
      ? null
      : '올바른 이메일 형식이 아닙니다.';
  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#$%^&*]').hasMatch(password)) {
      return '비밀번호는 대문자·소문자·숫자·특수문자를 포함한 8자 이상이어야 합니다.';
    }
    return null;
  }
}
