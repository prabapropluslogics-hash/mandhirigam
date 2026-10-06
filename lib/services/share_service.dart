import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import 'book_link.dart';

/// Opens the native share sheet for a book's public link.
///
/// Only one share sheet is requested at a time; repeated taps while the sheet
/// is open are ignored.
class ShareService {
  ShareService({BookLinks? links}) : _links = links ?? BookLinks.current;

  final BookLinks _links;
  bool _sharing = false;

  bool get canShareBooks => _links.isConfigured;

  Uri? bookUrl(String bookId) => _links.bookUri(bookId);

  static String bookMessage(String title, Uri url) {
    final String name = title.trim();
    final String lead = name.isEmpty
        ? 'Read on ${AppConstants.appName}.'
        : 'Read "$name" on ${AppConstants.appName}.';
    return '$lead\n\n$url';
  }

  /// Returns false when sharing is unavailable or already in progress.
  Future<bool> shareBook(
    BuildContext context, {
    required String bookId,
    required String title,
  }) async {
    if (_sharing) return false;
    final Uri? url = bookUrl(bookId);
    if (url == null) return false;
    final RenderObject? box = context.findRenderObject();
    final Rect? origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    _sharing = true;
    try {
      await Share.share(
        bookMessage(title, url),
        subject: title.trim().isEmpty ? AppConstants.appName : title.trim(),
        sharePositionOrigin: origin,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _sharing = false;
    }
  }
}
