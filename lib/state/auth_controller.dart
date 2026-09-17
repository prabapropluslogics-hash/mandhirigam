import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  UserProfile? user;
  bool restoring = true;
  bool signingIn = false;
  bool sessionExpired = false;
  String? errorMessage;
  bool _handlingUnauthorized = false;

  bool get isAuthenticated => user != null;

  Future<void> restore() async {
    restoring = true;
    notifyListeners();
    try {
      final GoogleAuthResult? session = await _repository.restore();
      user = session?.user;
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    signingIn = true;
    errorMessage = null;
    notifyListeners();
    try {
      final GoogleAuthResult? result = await _repository.signInWithGoogle();
      if (result == null) {
        return false;
      }
      user = result.user;
      return true;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
      return false;
    } catch (_) {
      errorMessage = 'Google sign-in could not be completed.';
      return false;
    } finally {
      signingIn = false;
      notifyListeners();
    }
  }

  Future<void> handleUnauthorized(ApiException error) async {
    if (!error.isUnauthorized) return;
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
    await _repository.signOutLocal();
    user = null;
    errorMessage = null;
    notifyListeners();
  }
}
