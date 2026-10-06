import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/errors/api_exception.dart';
import 'google_auth_gateway.dart';

/// Firebase user fields the app relies on.
class FirebaseIdentity {
  const FirebaseIdentity({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
}

abstract class FirebaseAuthGateway {
  /// False when Firebase could not be initialized for this platform.
  bool get isAvailable;

  /// Resolves the persisted Firebase user after app start.
  Future<FirebaseIdentity?> restoreUser();

  Stream<FirebaseIdentity?> userChanges();

  Future<FirebaseIdentity> signInWithGoogle(GoogleCredentials credentials);

  Future<void> signOut();
}

class FirebaseAuthService implements FirebaseAuthGateway {
  FirebaseAuthService({FirebaseAuth? auth}) : _authOverride = auth;

  final FirebaseAuth? _authOverride;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  @override
  bool get isAvailable => _authOverride != null || Firebase.apps.isNotEmpty;

  @override
  Future<FirebaseIdentity?> restoreUser() async {
    if (!isAvailable) return null;
    final User? user = await _auth
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => _auth.currentUser);
    return user == null ? null : _identity(user);
  }

  @override
  Stream<FirebaseIdentity?> userChanges() {
    if (!isAvailable) return const Stream<FirebaseIdentity?>.empty();
    return _auth
        .authStateChanges()
        .map((User? user) => user == null ? null : _identity(user));
  }

  @override
  Future<FirebaseIdentity> signInWithGoogle(GoogleCredentials credentials) async {
    if (!isAvailable) throw _notConfigured;
    try {
      final UserCredential result = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(
          idToken: credentials.idToken,
          accessToken: credentials.accessToken,
        ),
      );
      final User? user = result.user;
      if (user == null) {
        throw const ApiException(
          statusCode: 0,
          code: 'FIREBASE_AUTH_FAILED',
          message: 'Firebase did not return a user.',
        );
      }
      return _identity(user);
    } on FirebaseAuthException catch (error) {
      throw _mapAuthError(error);
    } on FirebaseException {
      throw _notConfigured;
    }
  }

  @override
  Future<void> signOut() async {
    if (!isAvailable) return;
    await _auth.signOut();
  }

  static const GoogleSignInConfigException _notConfigured =
      GoogleSignInConfigException(
    'Firebase is not configured for this platform build.',
  );

  static FirebaseIdentity _identity(User user) {
    return FirebaseIdentity(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }

  static Exception _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'network-request-failed':
        return const NetworkException();
      case 'too-many-requests':
        return const ApiException(
          statusCode: 429,
          code: 'RATE_LIMITED',
          message: 'Too many attempts.',
        );
      case 'invalid-credential':
      case 'user-token-expired':
        return const ApiException(
          statusCode: 401,
          code: 'FIREBASE_CREDENTIAL_INVALID',
          message: 'Google credential is invalid or expired.',
        );
      case 'user-disabled':
        return const ApiException(
          statusCode: 403,
          code: 'USER_INACTIVE',
          message: 'This account is disabled.',
        );
      case 'account-exists-with-different-credential':
        return const ApiException(
          statusCode: 409,
          code: 'FIREBASE_ACCOUNT_CONFLICT',
          message: 'Account exists with a different sign-in method.',
        );
      case 'operation-not-allowed':
        return const GoogleSignInConfigException(
          'Google sign-in is not enabled in Firebase Authentication.',
        );
      case 'app-not-authorized':
      case 'invalid-api-key':
        return const GoogleSignInConfigException(
          'This app is not authorized to use Firebase Authentication.',
        );
      default:
        return const ApiException(
          statusCode: 0,
          code: 'FIREBASE_AUTH_FAILED',
          message: 'Firebase sign-in failed.',
        );
    }
  }
}
