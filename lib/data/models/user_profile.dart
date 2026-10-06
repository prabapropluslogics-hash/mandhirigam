import '../../core/utils/json_map.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    this.firebaseUid,
  });

  /// Mantirigam backend user id.
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final String? firebaseUid;

  String get initials {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final List<String> parts =
        trimmed.split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    String? firebaseUid,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      firebaseUid: firebaseUid ?? this.firebaseUid,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: asString(json['id']),
      name: asString(json['name']),
      email: asString(json['email']),
      profileImageUrl: asStringOrNull(json['profileImageUrl']),
      firebaseUid: asStringOrNull(json['firebaseUid']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'firebaseUid': firebaseUid,
    };
  }
}

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final UserProfile user;

  factory GoogleAuthResult.fromJson(Map<String, dynamic> json) {
    return GoogleAuthResult(
      accessToken: asString(json['accessToken']),
      user: UserProfile.fromJson(asJsonMap(json['user'])),
    );
  }
}
