import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Best-effort cleanup for private PDF temp files.
///
/// The primary loader uses authenticated Range streaming (no disk). This
/// exists so any future/fallback temp files under the app-private temp
/// directory are never left behind after logout or stale sessions.
class PdfTempCleanup {
  static const String directoryName = 'maanthirigam_pdf';
  static const String filePrefix = 'chapter_pdf_';

  static Future<Directory?> _dir() async {
    try {
      final Directory base = await getTemporaryDirectory();
      return Directory('${base.path}${Platform.pathSeparator}$directoryName');
    } catch (error) {
      debugPrint('PDF temp dir unavailable: $error');
      return null;
    }
  }

  /// Deletes orphaned `chapter_pdf_*` files. Safe on startup / logout.
  static Future<void> clearAll() async {
    final Directory? dir = await _dir();
    if (dir == null || !await dir.exists()) return;
    try {
      await for (final FileSystemEntity entity in dir.list()) {
        if (entity is! File) continue;
        final String name = entity.uri.pathSegments.isEmpty
            ? entity.path
            : entity.uri.pathSegments.last;
        if (!name.startsWith(filePrefix)) continue;
        try {
          await entity.delete();
        } catch (error) {
          debugPrint('Could not delete PDF temp $name: $error');
        }
      }
    } catch (error) {
      debugPrint('PDF temp cleanup failed: $error');
    }
  }
}
