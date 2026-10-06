import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/firebase_auth_gateway.dart';
import '../../data/services/google_auth_gateway.dart';

enum SignInOutcome { signedIn, cancelled, failed, busy }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  UserProfile? user;
  bool restoring = true;
  bool signingIn = false;
  bool sessionExpired = false;
  String? errorMessage;
  bool _handlingUnauthorized = false;
  bool _signingOut = false;
  StreamSubscription<FirebaseIdentity?>? _firebaseUserSub;
  Future<String?>? _refreshInFlight;

  bool get isAuthenticated => user != null;

  Future<void> restore() async {
    restoring = true;
    notifyListeners();
    try {
      final GoogleAuthResult? session = await _repository.restore();
      user = session?.user;
      _firebaseUserSub ??=
          _repository.firebaseUserChanges().listen(_onFirebaseUserChanged);
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<SignInOutcome> signInWithGoogle() async {
    if (signingIn) return SignInOutcome.busy;
    signingIn = true;
    errorMessage = null;
    notifyListeners();
    try {
      final GoogleAuthResult? result = await _repository.signInWithGoogle();
      if (result == null) return SignInOutcome.cancelled;
      user = result.user;
      return SignInOutcome.signedIn;
    } on GoogleSignInConfigException catch (error) {
      debugPrint('Google sign-in configuration error: ${error.message}');
      errorMessage = error.message;
      return SignInOutcome.failed;
    } on ApiException catch (error) {
      debugPrint('Google sign-in failed: $error');
      errorMessage = error.userMessage;
      return SignInOutcome.failed;
    } catch (error) {
      debugPrint('Google sign-in failed: $error');
      errorMessage = 'Google sign-in could not be completed. Please try again.';
      return SignInOutcome.failed;
    } finally {
      signingIn = false;
      notifyListeners();
    }
  }

  /// Silently renews an expired API token. Concurrent 401s share one attempt.
  /// Returns `null` when the user must sign in again.
  Future<String?> refreshAccessToken() {
    if (!isAuthenticated || _signingOut) return Future<String?>.value();
    return _refreshInFlight ??= _refresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _refresh() async {
    final String? token = await _repository.refreshSession();
    if (token != null && isAuthenticated) {
      final UserProfile? refreshed = await _repository.storedUser();
      if (refreshed != null) {
        user = refreshed;
        notifyListeners();
      }
    }
    return token;
  }

  /// Firebase can drop its user on its own (account disabled, token revoked).
  void _onFirebaseUserChanged(FirebaseIdentity? identity) {
    if (identity != null || user == null || signingIn || _signingOut) return;
    if (_handlingUnauthorized) return;
    sessionExpired = true;
    unawaited(signOutLocal());
  }

  Future<void> handleUnauthorized(ApiException error) async {
    if (!error.isUnauthorized || !isAuthenticated) return;
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    sessionExpired = true;
    try {
      await signOutLocal();
    } finally {
      _handlingUnauthorized = false;
    }
  }

  void consumeSessionExpired() {
    sessionExpired = false;
  }

  Future<void> signOutLocal() async {
    _signingOut = true;
    try {
      await _repository.signOutLocal();
    } finally {
      _signingOut = false;
    }
    user = null;
    errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _firebaseUserSub?.cancel();
    super.dispose();
  }
}
