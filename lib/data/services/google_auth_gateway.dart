import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_env.dart';

abstract class GoogleAuthGateway {
  Future<String?> requestIdToken();
  Future<void> clearGoogleSession();
}

class GoogleSignInGateway implements GoogleAuthGateway {
  GoogleSignInGateway({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const <String>['email', 'profile'],
              serverClientId: AppEnv.googleServerClientId.isEmpty
                  ? null
                  : AppEnv.googleServerClientId,
            );

  final GoogleSignIn _googleSignIn;

  @override
  Future<String?> requestIdToken() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) return null;
    final GoogleSignInAuthentication auth = await account.authentication;
    return auth.idToken;
  }

  @override
  Future<void> clearGoogleSession() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Local Google session is not the Mantirigam session.
    }
  }
}
