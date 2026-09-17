import 'package:url_launcher/url_launcher.dart';

import 'safe_url.dart';

Future<bool> openSafeHttpUrl(String? raw) async {
  final Uri? uri = parseSafeHttpUrl(raw);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
