import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_colors.dart';
import 'core/validation/sign_up_validators.dart';
import 'data/models/create_member_request.dart';
import 'view_models/learning_member_session.dart';
import 'view_models/sign_up_view_model.dart';
import 'widgets/movielog_button.dart';

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

  bool get _canSubmit =>
      SignUpValidators.nickname(_nicknameController.text) == null &&
      SignUpValidators.email(_emailController.text) == null &&
      SignUpValidators.password(_passwordController.text) == null &&
      context.read<SignUpViewModel>().checksPassed &&
      _agreedToTerms &&
      context.read<SignUpViewModel>().submitStatus != SubmitStatus.submitting;

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

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_canSubmit) return;
    FocusScope.of(context).unfocus();
    final vm = context.read<SignUpViewModel>();
    await vm.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );
    if (!mounted) return;
    if (vm.submitStatus == SubmitStatus.success && vm.createdMemberId != null) {
      context.read<LearningMemberSession>().setMemberId(vm.createdMemberId!);
      context.go('/movies');
    } else if (vm.snackbarMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(vm.snackbarMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final viewModel = context.watch<SignUpViewModel>();

    return PopScope(
      canPop: viewModel.submitStatus != SubmitStatus.submitting,
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
          leading: BackButton(
            onPressed: viewModel.submitStatus == SubmitStatus.submitting
                ? null
                : () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Align(
              alignment: Alignment.topCenter,
              child: AbsorbPointer(
                absorbing: viewModel.submitStatus == SubmitStatus.submitting,
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
                            fieldKey: const Key('signup-nickname'),
                            validator: SignUpValidators.nickname,
                            serverErrorText: viewModel.nicknameErrorText,
                            serverAvailable:
                                viewModel.nicknameCheckStatus ==
                                CheckStatus.available,
                            successText:
                                viewModel.nicknameCheckStatus ==
                                    CheckStatus.available
                                ? '사용할 수 있는 닉네임입니다.'
                                : null,
                            trailing: MovieLogButton(
                              key: const Key('check-nickname'),
                              label: '중복 확인',
                              isLoading:
                                  viewModel.nicknameCheckStatus ==
                                  CheckStatus.checking,
                              onPressed: viewModel.canCheckNickname
                                  ? () => viewModel.checkNickname(
                                      _nicknameController.text,
                                    )
                                  : null,
                            ),
                            autofillHints: const [AutofillHints.nickname],
                            onChanged: (value) {
                              viewModel.onNicknameChanged(value);
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
                            fieldKey: const Key('signup-email'),
                            validator: SignUpValidators.email,
                            serverErrorText: viewModel.emailErrorText,
                            serverAvailable:
                                viewModel.emailCheckStatus ==
                                CheckStatus.available,
                            successText:
                                viewModel.emailCheckStatus ==
                                    CheckStatus.available
                                ? '사용할 수 있는 이메일입니다.'
                                : null,
                            trailing: MovieLogButton(
                              key: const Key('check-email'),
                              label: '중복 확인',
                              isLoading:
                                  viewModel.emailCheckStatus ==
                                  CheckStatus.checking,
                              onPressed: viewModel.canCheckEmail
                                  ? () => viewModel.checkEmail(
                                      _emailController.text,
                                    )
                                  : null,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            onChanged: (value) {
                              viewModel.onEmailChanged(value);
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
                            fieldKey: const Key('signup-password'),
                            validator: SignUpValidators.password,
                            serverErrorText: viewModel.passwordErrorText,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onChanged: (_) {
                              viewModel.onPasswordChanged();
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

                          MovieLogButton(
                            key: const Key('signup-submit'),
                            label: '가입하기',
                            isLoading:
                                viewModel.submitStatus ==
                                SubmitStatus.submitting,
                            width: double.infinity,
                            onPressed: _canSubmit ? _submit : null,
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
      ),
    );
  }
}

// 회원가입 화면에서 사용하는 상태별 색상
class _SignUpColors {
  static const error = Color(0xFFB3261E);
  static const errorBackground = Color(0xFFFFDAD6);
  static const inputBorder = Color(0xFFCAC6CE);
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
    this.fieldKey,
    this.trailing,
    this.serverErrorText,
    this.serverAvailable,
    this.successText,
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
  final Key? fieldKey;
  final Widget? trailing;
  final String? serverErrorText;
  final bool? serverAvailable;
  final String? successText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // 아이콘과 배경도 동일한 검사 규칙을 사용해.
    final errorText = validator(controller.text) ?? serverErrorText;
    final hasError = serverErrorText != null || (touched && errorText != null);
    final isValid = touched && errorText == null && (serverAvailable ?? true);

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

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: fieldKey,
                validator: validator,
                // forceErrorText also makes Form.validate fail for a server error.
                forceErrorText: serverErrorText,
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
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  errorText: serverErrorText,
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
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.only(top: 6), child: trailing!),
            ],
          ],
        ),
        if (successText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              successText!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.primary),
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
            FocusScope.of(context).unfocus();
            context.go('/home');
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
