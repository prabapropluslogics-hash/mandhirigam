import '../models/user_profile.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json_map.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<GoogleAuthResult> signInWithGoogleIdToken(String idToken) async {
    final envelope = await _client.post(
      '/auth/google',
      body: <String, dynamic>{'idToken': idToken},
    );
    return GoogleAuthResult.fromJson(asJsonMap(envelope.data));
  }
}
