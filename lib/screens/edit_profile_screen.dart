import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nickname;
  late final String _initial;
  bool _saving = false, _allowPop = false;
  String? _error;
  @override
  void initState() { super.initState(); _initial = context.read<AuthViewModel>().member?.nickname ?? ''; _nickname = TextEditingController(text: _initial); }
  @override void dispose() { _nickname.dispose(); super.dispose(); }
  Future<void> _save() async {
    if (_saving) return;
    final nickname = _nickname.text.trim();
    if (nickname.characters.length < 2 || nickname.characters.length > 12) { setState(() => _error = '닉네임은 2~12자로 입력해 주세요.'); return; }
    if (nickname == _initial) { _finish(); return; }
    final auth = context.read<AuthViewModel>(); final api = context.read<MemberApiService>(); final version = auth.sessionVersion;
    setState(() { _saving = true; _error = null; });
    try {
      final updated = await api.updateNickname(nickname);
      if (!mounted || version != auth.sessionVersion || auth.status != AuthStatus.signedIn) return;
      auth.updateMember(updated, version); _finish();
    } on DioException catch (error) {
      if (!mounted || version != auth.sessionVersion) return;
      switch (apiErrorCode(error)) {
        case 'MEMBER409_1': setState(() => _error = '이미 사용 중인 닉네임이에요.');
        case 'MEMBER404_1': ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원 정보를 찾을 수 없어요.')));
        case 'COMMON400': setState(() => _error = apiErrorMessage(error) ?? '닉네임을 확인해 주세요.');
        default: ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.')));
      }
    } catch (_) {
      if (mounted && version == auth.sessionVersion) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필 응답을 확인하지 못했어요.')));
    } finally { if (mounted) setState(() => _saving = false); }
  }
  void _finish() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      if (context.canPop()) { context.pop(); } else { context.go('/my'); }
    });
  }
  Future<void> _confirmBack() async {
    if (_saving) return;
    if (_nickname.text.trim() == _initial) { _pop(); return; }
    final leave = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('변경을 취소할까요?'), content: const Text('저장하지 않은 내용은 사라져요.'), actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('계속 수정')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('나가기')),
    ]));
    if (mounted && leave == true) _pop();
  }
  void _pop() { setState(() => _allowPop = true); WidgetsBinding.instance.addPostFrameCallback((_) { if (!mounted) return; if (context.canPop()) { context.pop(); } else { context.go('/my'); } }); }
  @override
  Widget build(BuildContext context) {
    final member = context.watch<AuthViewModel>().member;
    return PopScope(canPop: _allowPop, onPopInvokedWithResult: (didPop, _) { if (!didPop) _confirmBack(); }, child: Scaffold(
      appBar: AppBar(title: const Text('프로필 수정'), centerTitle: true, leading: BackButton(onPressed: _saving ? null : _confirmBack)),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(initialValue: member?.email ?? '', enabled: false, decoration: const InputDecoration(labelText: '이메일')),
        const SizedBox(height: 16), TextField(key: const Key('profile-nickname'), controller: _nickname, enabled: !_saving, maxLength: 12, onChanged: (_) { if (_error != null) setState(() => _error = null); }, decoration: InputDecoration(labelText: '닉네임', errorText: _error)),
        const Spacer(), MovieLogButton(label: '저장', isLoading: _saving, width: double.infinity, onPressed: _saving ? null : _save),
      ]))),
    ));
  }
}
