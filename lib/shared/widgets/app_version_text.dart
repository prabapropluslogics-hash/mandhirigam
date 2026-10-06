import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed app version, e.g. "1.0.0 (12)", read from the platform.
class AppVersionText extends StatelessWidget {
  const AppVersionText({super.key, this.style, this.prefix = ''});

  final TextStyle? style;
  final String prefix;

  static Future<String?>? _version;

  static Future<String?> _load() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      if (info.version.isEmpty) return null;
      return info.buildNumber.isEmpty
          ? info.version
          : '${info.version} (${info.buildNumber})';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _version ??= _load(),
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        final String? version = snapshot.data;
        if (version == null) return const SizedBox.shrink();
        return Text('$prefix$version', style: style);
      },
    );
  }
}
