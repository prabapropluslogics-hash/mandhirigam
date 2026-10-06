import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_env.dart';
import '../../core/errors/api_exception.dart';

/// Tokens returned by the Google account picker.
class GoogleCredentials {
  const GoogleCredentials({required this.idToken, this.accessToken});

  final String idToken;
  final String? accessToken;
}

abstract class GoogleAuthGateway {
  /// Returns `null` when the user cancels the account picker.
  Future<GoogleCredentials?> requestCredentials();

  /// Fresh tokens for the previously signed-in account without any UI.
  /// Returns `null` when that is not possible.
  Future<GoogleCredentials?> silentCredentials();

  Future<void> clearGoogleSession();
}

/// Thrown when Google Sign-In / Firebase cannot complete due to missing setup.
class GoogleSignInConfigException implements Exception {
  const GoogleSignInConfigException(this.message);
  final String message;

  @override
  String toString() => 'GoogleSignInConfigException: $message';
}

class GoogleSignInGateway implements GoogleAuthGateway {
  GoogleSignInGateway({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const <String>['email', 'profile'],
              // On Android, null falls back to `default_web_client_id`
              // generated from google-services.json.
              serverClientId: AppEnv.googleServerClientId.isEmpty
                  ? null
                  : AppEnv.googleServerClientId,
            );

  final GoogleSignIn _googleSignIn;

  // Google Play services status codes surfaced in PlatformException messages.
  static const String _statusDeveloperError = 'ApiException: 10';
  static const String _statusNetworkError = 'ApiException: 7';
  static const String _statusCancelled = 'ApiException: 12501';

  @override
  Future<GoogleCredentials?> requestCredentials() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleSignInConfigException(
          'Google did not return an ID token. Confirm the Web client ID and '
          'the app signing SHA-1 are registered in Firebase.',
        );
      }
      return GoogleCredentials(idToken: idToken, accessToken: auth.accessToken);
    } on PlatformException catch (error) {
      final String details = '${error.message ?? ''} ${error.details ?? ''}';
      if (error.code == GoogleSignIn.kSignInCanceledError ||
          details.contains(_statusCancelled)) {
        return null;
      }
      if (error.code == GoogleSignIn.kNetworkError ||
          details.contains(_statusNetworkError)) {
        throw const NetworkException();
      }
      if (details.contains(_statusDeveloperError)) {
        throw const GoogleSignInConfigException(
          'Google Sign-In is not configured for this build. Check the package '
          'name, SHA-1 fingerprint and OAuth client in Firebase.',
        );
      }
      throw const ApiException(
        statusCode: 0,
        code: 'GOOGLE_SIGN_IN_FAILED',
        message: 'Google sign-in could not be completed. Please try again.',
      );
    }
  }

  @override
  Future<GoogleCredentials?> silentCredentials() async {
    try {
      final GoogleSignInAccount? account =
          await _googleSignIn.signInSilently(suppressErrors: true);
      if (account == null) return null;
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) return null;
      return GoogleCredentials(idToken: idToken, accessToken: auth.accessToken);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearGoogleSession() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // The cached Google account is not the Mantirigam session.
    }
  }
}
