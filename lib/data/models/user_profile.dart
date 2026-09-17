import '../../core/utils/json_map.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;

  String get initials {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final List<String> parts =
        trimmed.split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: asString(json['id']),
      name: asString(json['name']),
      email: asString(json['email']),
      profileImageUrl: asStringOrNull(json['profileImageUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
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
