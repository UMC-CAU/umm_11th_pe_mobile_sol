import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'support/week6_fakes.dart';

void main() {
  test('invalid fields cannot send requests', () async {
    final service = FakeMemberCheckService();
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('한');
    vm.onEmailChanged('invalid');
    await vm.checkNickname('한');
    await vm.checkEmail('invalid');
    expect(vm.canCheckNickname, isFalse);
    expect(vm.canCheckEmail, isFalse);
    expect(service.nicknames, isEmpty);
    expect(service.emails, isEmpty);
  });

  test('nickname and email requests finish independently', () async {
    final nickname = Completer<bool>();
    final email = Completer<bool>();
    final service = FakeMemberCheckService();
    service.onNickname = (_) => nickname.future;
    service.onEmail = (_) => email.future;
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('한솔');
    vm.onEmailChanged('sol@example.com');
    final n = vm.checkNickname('한솔');
    final e = vm.checkEmail('sol@example.com');
    expect(vm.nicknameCheckStatus, CheckStatus.checking);
    expect(vm.emailCheckStatus, CheckStatus.checking);
    nickname.complete(true);
    await n;
    expect(vm.nicknameCheckStatus, CheckStatus.available);
    expect(vm.emailCheckStatus, CheckStatus.checking);
    email.complete(true);
    await e;
    expect(vm.checksPassed, isTrue);
    vm.onNicknameChanged('새닉네임');
    expect(vm.checksPassed, isFalse);
    expect(vm.emailCheckStatus, CheckStatus.available);
  });

  test('duplicate nickname is restored without a second API request', () async {
    final service = FakeMemberCheckService()..onNickname = (_) => false;
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('중복닉네임');
    await vm.checkNickname('중복닉네임');
    expect(vm.canCheckNickname, isFalse);
    vm.onNicknameChanged('새닉네임');
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    expect(vm.nicknameErrorText, isNull);
    expect(vm.canCheckNickname, isTrue);
    vm.onNicknameChanged(' 중복닉네임 ');
    await vm.checkNickname('중복닉네임');
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    expect(vm.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
    expect(service.nicknames, ['중복닉네임']);
  });

  test('duplicate email has its own cache', () async {
    final service = FakeMemberCheckService()..onEmail = (_) => false;
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onEmailChanged('taken@example.com');
    await vm.checkEmail('taken@example.com');
    vm.onNicknameChanged('변경닉네임');
    expect(vm.emailCheckStatus, CheckStatus.duplicated);
    vm.onEmailChanged('new@example.com');
    expect(vm.canCheckEmail, isTrue);
    vm.onEmailChanged('taken@example.com');
    expect(vm.canCheckEmail, isFalse);
    expect(vm.emailErrorText, '이미 사용 중인 이메일입니다.');
    expect(service.emails.length, 1);
  });

  test('A to B to A cannot reuse a late success response', () async {
    final response = Completer<bool>();
    final service = FakeMemberCheckService()
      ..onNickname = (_) => response.future;
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('첫닉네임');
    final pending = vm.checkNickname('첫닉네임');
    await vm.checkNickname('첫닉네임');
    expect(service.nicknames.length, 1);
    vm.onNicknameChanged('다른닉네임');
    vm.onNicknameChanged('첫닉네임');
    response.complete(true);
    await pending;
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
    expect(vm.checksPassed, isFalse);
  });

  test('transport error is retryable and differs from duplicated', () async {
    final service = FakeMemberCheckService()
      ..onEmail = (_) => throw testHttpError();
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onEmailChanged('sol@example.com');
    await vm.checkEmail('sol@example.com');
    expect(vm.emailCheckStatus, CheckStatus.error);
    expect(vm.emailErrorText, contains('실패'));
    expect(vm.canCheckEmail, isTrue);
    service.onEmail = (_) => false;
    await vm.checkEmail('sol@example.com');
    expect(vm.emailCheckStatus, CheckStatus.duplicated);
    expect(vm.emailErrorText, contains('이미 사용 중'));
  });

  test('response after route disposal does not notify or mutate', () async {
    final response = Completer<bool>();
    final vm = SignUpViewModel(
      FakeMemberCheckService()..onEmail = (_) => response.future,
    );
    var notifications = 0;
    vm.addListener(() => notifications++);
    vm.onEmailChanged('sol@example.com');
    final pending = vm.checkEmail('sol@example.com');
    final count = notifications;
    vm.dispose();
    response.complete(false);
    await pending;
    expect(notifications, count);
    expect(vm.emailCheckStatus, CheckStatus.checking);
  });
}
