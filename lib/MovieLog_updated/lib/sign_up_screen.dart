import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // build 밖에서 유지하는 Form 상태 접근 키
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nicknameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _nicknameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _agreedToTerms = false;

  String? _validateNickname(String? value) {
    if ((value ?? '').trim().characters.length < 2) {
      return '닉네임은 2자 이상이어야 합니다.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!pattern.hasMatch(email)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').characters.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    return null;
  }

  bool get _canSubmit =>
      _validateNickname(_nicknameController.text) == null &&
      _validateEmail(_emailController.text) == null &&
      _validatePassword(_passwordController.text) == null &&
      _agreedToTerms;

  @override
  void initState() {
    super.initState();

    _nicknameFocus.addListener(_onNicknameFocusChanged);
    _emailFocus.addListener(_onEmailFocusChanged);
    _passwordFocus.addListener(_onPasswordFocusChanged);
  }

  void _onNicknameFocusChanged() {
    if (!_nicknameFocus.hasFocus) {
      setState(() => _nicknameTouched = true);
    }
  }

  void _onEmailFocusChanged() {
    if (!_emailFocus.hasFocus) {
      setState(() => _emailTouched = true);
    }
  }

  void _onPasswordFocusChanged() {
    if (!_passwordFocus.hasFocus) {
      setState(() => _passwordTouched = true);
    }
  }

  @override
  void dispose() {
    _nicknameFocus.removeListener(_onNicknameFocusChanged);
    _emailFocus.removeListener(_onEmailFocusChanged);
    _passwordFocus.removeListener(_onPasswordFocusChanged);

    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();

    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  void _submit() {
    // Form 안의 모든 TextFormField.validator를 실행해.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_agreedToTerms) return;

    FocusScope.of(context).unfocus();

    // 이번 과제에서는 검증 완료 후 Mock 홈으로 이동합니다.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('회원가입'),
          centerTitle: true,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                // 너비만 제한하고 높이는 오류 문구를 포함한 내용에 맞춰 늘어나게 해.
                constraints: const BoxConstraints(maxWidth: 480),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(height: 1.7),
                        ),

                        const SizedBox(height: 52),

                        _ValidatedField(
                          label: '닉네임',
                          hintText: '닉네임을 입력해주세요',
                          controller: _nicknameController,
                          focusNode: _nicknameFocus,
                          touched: _nicknameTouched,
                          validator: _validateNickname,
                          autofillHints: const [AutofillHints.nickname],
                          onChanged: (_) {
                            setState(() => _nicknameTouched = true);
                          },
                          onSubmitted: (_) {
                            _emailFocus.requestFocus();
                          },
                        ),

                        const SizedBox(height: 24),

                        _ValidatedField(
                          label: '이메일',
                          hintText: '이메일 주소를 입력해주세요',
                          controller: _emailController,
                          focusNode: _emailFocus,
                          touched: _emailTouched,
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) {
                            setState(() => _emailTouched = true);
                          },
                          onSubmitted: (_) {
                            _passwordFocus.requestFocus();
                          },
                        ),

                        const SizedBox(height: 24),

                        _ValidatedField(
                          label: '비밀번호',
                          hintText: '비밀번호를 입력해주세요',
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          touched: _passwordTouched,
                          validator: _validatePassword,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) {
                            setState(() => _passwordTouched = true);
                          },
                          onSubmitted: (_) {
                            _passwordFocus.unfocus();
                          },
                        ),

                        const SizedBox(height: 48),

                        _TermsAgreement(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() => _agreedToTerms = value);
                          },
                        ),

                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            disabledBackgroundColor: _SignUpColors.disabledButton,
                            disabledForegroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: textTheme.titleMedium,
                          ),
                          child: const Text('가입하기'),
                        ),

                        const SizedBox(height: 32),

                        const _LoginPrompt(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 회원가입 화면에서 사용하는 상태별 색상
class _SignUpColors {
  static const error = Color(0xFFB3261E);
  static const errorBackground = Color(0xFFFFDAD6);
  static const inputBorder = Color(0xFFCAC6CE);
  static const disabledButton = Color(0xFFCEC3DE);
}

// 입력 상태에 따라 배경, 테두리, 아이콘을 바꾸는 공통 입력창
class _ValidatedField extends StatelessWidget {
  const _ValidatedField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    required this.touched,
    required this.validator,
    required this.onChanged,
    required this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.autofillHints,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool touched;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // 아이콘과 배경도 동일한 검사 규칙을 사용해.
    final errorText = validator(controller.text);
    final hasError = touched && errorText != null;
    final isValid = touched && errorText == null;

    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.titleMedium),

        const SizedBox(height: 8),

        TextFormField(
          validator: validator,
          // 입력하거나 포커스를 잃은 항목만 실시간으로 검사해.
          autovalidateMode: touched
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          obscuringCharacter: '•',
          autofillHints: autofillHints,
          autocorrect: false,
          enableSuggestions: !obscureText,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: textTheme.bodyMedium,
            filled: true,
            fillColor: hasError
                ? _SignUpColors.errorBackground
                : AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: border(_SignUpColors.inputBorder),
            focusedBorder: border(AppColors.primary),
            errorBorder: border(_SignUpColors.error),
            focusedErrorBorder: border(_SignUpColors.error),
            errorMaxLines: 2,
            errorStyle: textTheme.bodySmall?.copyWith(
              color: _SignUpColors.error,
            ),
            suffixIcon: hasError
                ? const Icon(
                    Icons.error_outline,
                    color: _SignUpColors.error,
                    semanticLabel: '입력 오류',
                  )
                : isValid
                ? const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    semanticLabel: '입력 조건 충족',
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// 약관 문구를 눌러도 체크 상태가 바뀌어.
class _TermsAgreement extends StatelessWidget {
  const _TermsAgreement({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      title: Text(
        '필수 약관에 동의합니다',
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.textPrimary),
      ),
      activeColor: AppColors.primary,
      checkColor: AppColors.onPrimary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('이미 계정이 있나요?', style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('로그인 화면은 준비 중입니다.')));
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide.none,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
          child: const Text('로그인'),
        ),
      ],
    );
  }
}
