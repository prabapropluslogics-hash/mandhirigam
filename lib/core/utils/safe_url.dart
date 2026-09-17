Uri? parseSafeHttpUrl(String? raw) {
  if (raw == null) return null;
  final String value = raw.trim();
  if (value.isEmpty) return null;
  final Uri? uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme) return null;
  final String scheme = uri.scheme.toLowerCase();
  if (scheme == 'https' || scheme == 'http') {
    return uri;
  }
  return null;
}
