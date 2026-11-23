import '../../view_models/auth_view_model.dart';
import 'session_guard.dart';

class AuthSessionBridge {
  AuthSessionBridge(this._auth) {
    _auth.addListener(_sync);
    _sync();
  }

  final AuthViewModel _auth;
  final guard = SessionGuard();
  ({int version, String? email})? _identity;

  void _sync() {
    final identity = (
      version: _auth.sessionVersion,
      email: _auth.status == AuthStatus.signedIn ? _auth.member?.email : null,
    );
    if (identity == _identity) return;
    _identity = identity;
    guard.replaceAccount(identity.email);
  }

  void dispose() {
    _auth.removeListener(_sync);
    guard.replaceAccount(null);
  }
}
