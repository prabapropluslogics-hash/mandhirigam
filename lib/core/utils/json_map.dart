Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Expected a JSON object.');
}

List<Map<String, dynamic>> asJsonMapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Object>()
      .map(asJsonMap)
      .toList(growable: false);
}

String? asStringOrNull(Object? value) {
  if (value == null) return null;
  final String text = value.toString();
  return text.isEmpty ? null : text;
}

String asString(Object? value, [String fallback = '']) {
  return asStringOrNull(value) ?? fallback;
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool asBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return fallback;
}
