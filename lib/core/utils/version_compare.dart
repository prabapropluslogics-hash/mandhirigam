int compareSemver(String a, String b) {
  List<int> parts(String value) {
    return value
        .split('.')
        .map((String part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  final List<int> left = parts(a);
  final List<int> right = parts(b);
  final int length = left.length > right.length ? left.length : right.length;
  for (int i = 0; i < length; i++) {
    final int l = i < left.length ? left[i] : 0;
    final int r = i < right.length ? right[i] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}

enum AppUpdateKind { none, optional, required }

AppUpdateKind resolveAppUpdate({
  required String currentVersion,
  required String? latestVersion,
  required String? minimumVersion,
  required bool forceUpdateEnabled,
}) {
  if (minimumVersion != null &&
      minimumVersion.isNotEmpty &&
      compareSemver(currentVersion, minimumVersion) < 0) {
    return forceUpdateEnabled ? AppUpdateKind.required : AppUpdateKind.optional;
  }
  if (latestVersion != null &&
      latestVersion.isNotEmpty &&
      compareSemver(currentVersion, latestVersion) < 0) {
    return AppUpdateKind.optional;
  }
  return AppUpdateKind.none;
}
