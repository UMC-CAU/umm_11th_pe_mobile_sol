import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberEmail = false;
  bool _obscure = true;
  static const _emailKey = 'login.saved_email';
  @override
  void initState() {
    super.initState(); _loadEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthViewModel>().takeExpiredNotice()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 세션이 만료되었어요. 다시 로그인해 주세요.')));
      }
    });
  }
  Future<void> _loadEmail() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_emailKey);
      if (!mounted || saved == null || _email.text.isNotEmpty) return;
      setState(() { _email.text = saved; _rememberEmail = true; });
    } catch (_) {}
  }
  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthViewModel>(); final email = _email.text.trim(); final password = _password.text;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberEmail) { await prefs.setString(_emailKey, email); } else { await prefs.remove(_emailKey); }
    } catch (_) {}
    if (!mounted) return;
    await auth.login(email, password);
  }
  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final working = auth.status == AuthStatus.authenticating || auth.storageCleanupInProgress || auth.storageCleanupFailed;
    return Scaffold(appBar: AppBar(title: const Text('로그인'), centerTitle: true), body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480), child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 32), Text('다시 만나서 반가워요', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 32),
          TextFormField(key: const Key('login-email'), controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], enabled: !working,
            decoration: const InputDecoration(labelText: '이메일'), validator: (value) => value == null || !value.trim().contains('@') ? '이메일을 확인해 주세요.' : null),
          const SizedBox(height: 16),
          TextFormField(key: const Key('login-password'), controller: _password, obscureText: _obscure, autofillHints: const [AutofillHints.password], enabled: !working,
            decoration: InputDecoration(labelText: '비밀번호', suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility))),
            validator: (value) => value == null || value.isEmpty ? '비밀번호를 입력해 주세요.' : null),
          CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('이메일 저장'), value: _rememberEmail,
            onChanged: working ? null : (value) => setState(() => _rememberEmail = value ?? false), controlAffinity: ListTileControlAffinity.leading),
          if (auth.message != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(auth.message!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (auth.storageCleanupFailed) TextButton(onPressed: auth.storageCleanupInProgress ? null : auth.retryStorageCleanup, child: const Text('인증 정보 삭제 다시 시도')),
          MovieLogButton(label: '로그인', isLoading: auth.status == AuthStatus.authenticating || auth.storageCleanupInProgress, width: double.infinity, onPressed: working ? null : _submit),
          const SizedBox(height: 16), TextButton(onPressed: working ? null : () => context.push('/signup'), child: const Text('회원가입')),
        ]),
      )),
    ))));
  }
}
