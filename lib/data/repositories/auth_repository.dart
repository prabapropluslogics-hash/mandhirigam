import '../../core/storage/session_store.dart';
import '../models/user_profile.dart';
import '../services/auth_api.dart';
import '../services/firebase_auth_gateway.dart';
import '../services/google_auth_gateway.dart';

/// A signed-in session requires both a Firebase user and a Mantirigam
/// access token; any mismatch is treated as signed out.
class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required SessionStore sessionStore,
    required GoogleAuthGateway googleAuth,
    required FirebaseAuthGateway firebaseAuth,
  })  : _api = api,
        _sessionStore = sessionStore,
        _googleAuth = googleAuth,
        _firebaseAuth = firebaseAuth;

  final AuthApi _api;
  final SessionStore _sessionStore;
  final GoogleAuthGateway _googleAuth;
  final FirebaseAuthGateway _firebaseAuth;

  Stream<FirebaseIdentity?> firebaseUserChanges() => _firebaseAuth.userChanges();

  Future<GoogleAuthResult?> restore() async {
    final String? token = await _sessionStore.readAccessToken();
    final UserProfile? user = await _sessionStore.readUser();
    final FirebaseIdentity? identity = await _firebaseAuth.restoreUser();
    if (token != null && token.isNotEmpty && user != null) {
      if (identity != null) {
        return GoogleAuthResult(accessToken: token, user: _merge(user, identity));
      }
      await _clearAll();
    } else if (identity != null) {
      await _clearAll();
    }
    return null;
  }

  Future<GoogleAuthResult?> signInWithGoogle() async {
    if (!_firebaseAuth.isAvailable) {
      throw const GoogleSignInConfigException(
        'Firebase is not configured for this platform build.',
      );
    }
    final GoogleCredentials? credentials = await _googleAuth.requestCredentials();
    if (credentials == null) return null;
    try {
      final FirebaseIdentity identity =
          await _firebaseAuth.signInWithGoogle(credentials);
      return await _exchange(credentials, identity);
    } catch (_) {
      await _signOutFirebase();
      // Forget the picked account so another one can be chosen on retry.
      await _googleAuth.clearGoogleSession();
      rethrow;
    }
  }

  /// Re-issues the Mantirigam access token after it expired, using a silent
  /// Google sign-in for the still-signed-in Firebase user. Returns the new
  /// token, or `null` when the user has to sign in interactively.
  Future<String?> refreshSession() async {
    try {
      final FirebaseIdentity? identity = await _firebaseAuth.restoreUser();
      if (identity == null) return null;
      final GoogleCredentials? credentials =
          await _googleAuth.silentCredentials();
      if (credentials == null) return null;
      final GoogleAuthResult result = await _exchange(credentials, identity);
      return result.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<GoogleAuthResult> _exchange(
    GoogleCredentials credentials,
    FirebaseIdentity identity,
  ) async {
    final GoogleAuthResult backend =
        await _api.signInWithGoogleIdToken(credentials.idToken);
    final GoogleAuthResult result = GoogleAuthResult(
      accessToken: backend.accessToken,
      user: _merge(backend.user, identity),
    );
    await _sessionStore.saveSession(
      accessToken: result.accessToken,
      user: result.user,
    );
    return result;
  }

  Future<UserProfile?> storedUser() => _sessionStore.readUser();

  Future<void> signOutLocal() => _clearAll();

  Future<void> _clearAll() async {
    await _sessionStore.clear();
    await _signOutFirebase();
    await _googleAuth.clearGoogleSession();
  }

  Future<void> _signOutFirebase() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      // A stale Firebase user is reconciled on the next restore().
    }
  }

  static UserProfile _merge(UserProfile user, FirebaseIdentity identity) {
    return user.copyWith(
      name: user.name.isEmpty ? identity.displayName : null,
      email: user.email.isEmpty ? identity.email : null,
      profileImageUrl: user.profileImageUrl ?? identity.photoUrl,
      firebaseUid: identity.uid,
    );
  }
}
