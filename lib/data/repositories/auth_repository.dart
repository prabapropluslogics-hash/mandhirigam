import '../../core/storage/session_store.dart';
import '../models/user_profile.dart';
import '../services/auth_api.dart';
import '../services/google_auth_gateway.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required SessionStore sessionStore,
    required GoogleAuthGateway googleAuth,
  })  : _api = api,
        _sessionStore = sessionStore,
        _googleAuth = googleAuth;

  final AuthApi _api;
  final SessionStore _sessionStore;
  final GoogleAuthGateway _googleAuth;

  Future<GoogleAuthResult?> restore() async {
    final String? token = await _sessionStore.readAccessToken();
    final UserProfile? user = await _sessionStore.readUser();
    if (token == null || token.isEmpty || user == null) return null;
    return GoogleAuthResult(accessToken: token, user: user);
  }

  Future<GoogleAuthResult?> signInWithGoogle() async {
    final String? idToken = await _googleAuth.requestIdToken();
    if (idToken == null || idToken.isEmpty) return null;
    try {
      final GoogleAuthResult result = await _api.signInWithGoogleIdToken(idToken);
      await _sessionStore.saveSession(
        accessToken: result.accessToken,
        user: result.user,
      );
      return result;
    } finally {
      await _googleAuth.clearGoogleSession();
    }
  }

  Future<void> signOutLocal() async {
    await _sessionStore.clear();
    await _googleAuth.clearGoogleSession();
  }
}
