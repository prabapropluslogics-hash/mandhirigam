import '../../core/utils/json_map.dart';

/// One page inside an active transparent PNG package.
///
/// Field names match `docs/MOBILE_APP_INTEGRATION.md`. No media id or
/// storage key is part of this contract.
class TransparentPage {
  const TransparentPage({
    required this.pageNumber,
    required this.size,
    required this.sha256,
    required this.downloadPath,
  });

  final int pageNumber;
  final int size;
  final String sha256;
  final String downloadPath;

  factory TransparentPage.fromJson(Map<String, dynamic> json) {
    return TransparentPage(
      pageNumber: asInt(json['pageNumber']),
      size: asInt(json['size']),
      sha256: asString(json['sha256']).trim().toLowerCase(),
      downloadPath: asString(json['downloadPath']).trim(),
    );
  }

  /// Path relative to `API_BASE_URL`, without a second `/api/v1`.
  String get apiRelativePath => apiRelativeDownloadPath(downloadPath);
}

/// Active transparent package metadata returned with an Original PDF chapter.
class TransparentPagesDocument {
  const TransparentPagesDocument({
    required this.packageId,
    required this.sourcePdfSha256,
    required this.catalogFingerprint,
    required this.pageCount,
    required this.width,
    required this.height,
    required this.processorVersion,
    required this.pages,
  });

  final String packageId;
  final String sourcePdfSha256;
  final String catalogFingerprint;
  final int pageCount;
  final int width;
  final int height;
  final String processorVersion;
  final List<TransparentPage> pages;

  static final RegExp sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  /// Decoded RGBA byte budget. A page above this is rejected before decode.
  static const int maxPageBytes = 8 * 1024 * 1024;

  factory TransparentPagesDocument.fromJson(Map<String, dynamic> json) {
    final List<TransparentPage> pages = <TransparentPage>[];
    final Object? rawPages = json['pages'];
    if (rawPages is List) {
      for (final Object? item in rawPages) {
        if (item is Map) {
          pages.add(TransparentPage.fromJson(asJsonMap(item)));
        }
      }
    }
    return TransparentPagesDocument(
      packageId: asString(json['packageId']).trim(),
      sourcePdfSha256: asString(json['sourcePdfSha256']).trim().toLowerCase(),
      catalogFingerprint: asString(json['catalogFingerprint']).trim(),
      pageCount: asInt(json['pageCount']),
      width: asInt(json['width']),
      height: asInt(json['height']),
      processorVersion: asString(json['processorVersion']).trim(),
      pages: pages,
    );
  }

  TransparentPage? pageByNumber(int pageNumber) {
    for (final TransparentPage page in pages) {
      if (page.pageNumber == pageNumber) return page;
    }
    return null;
  }

  /// Returns a safe reason when this package must not be rendered.
  ///
  /// Does not change [ChapterDocument] rules. [documentSha256] is compared
  /// as already stored on the chapter document.
  String? validationError({
    required String bookId,
    required String chapterId,
    required String documentSha256,
    required int documentPageCount,
  }) {
    if (packageId.isEmpty) return 'Transparent package id is missing.';
    if (!sha256Pattern.hasMatch(sourcePdfSha256)) {
      return 'Transparent package source checksum is invalid.';
    }
    if (sourcePdfSha256 != documentSha256.trim().toLowerCase()) {
      return 'Transparent package does not match this PDF.';
    }
    if (catalogFingerprint.isEmpty) {
      return 'Transparent package fingerprint is missing.';
    }
    if (processorVersion.isEmpty) {
      return 'Transparent package processor version is missing.';
    }
    if (pageCount <= 0) return 'Transparent package page count is invalid.';
    if (pageCount != documentPageCount) {
      return 'Transparent package page count does not match this PDF.';
    }
    if (width <= 0 || height <= 0 || width > 4096 || height > 4096) {
      return 'Transparent page dimensions are invalid.';
    }
    if (pages.length != pageCount) {
      return 'Transparent package does not contain every page.';
    }
    final Set<int> seen = <int>{};
    final Set<String> paths = <String>{};
    for (var index = 0; index < pages.length; index++) {
      final TransparentPage page = pages[index];
      final int expectedNumber = index + 1;
      if (page.pageNumber != expectedNumber) {
        return 'Transparent pages are not in order.';
      }
      if (!seen.add(page.pageNumber)) {
        return 'Transparent pages repeat a page number.';
      }
      if (page.size <= 0 || page.size > maxPageBytes) {
        return 'Transparent page ${page.pageNumber} has an invalid size.';
      }
      if (!sha256Pattern.hasMatch(page.sha256)) {
        return 'Transparent page ${page.pageNumber} checksum is invalid.';
      }
      final String? pathError = validateTransparentDownloadPath(
        downloadPath: page.downloadPath,
        bookId: bookId,
        chapterId: chapterId,
        pageNumber: page.pageNumber,
      );
      if (pathError != null) return pathError;
      if (!paths.add(page.apiRelativePath)) {
        return 'Transparent pages repeat a download path.';
      }
    }
    return null;
  }
}

String apiRelativeDownloadPath(String downloadPath) {
  String path = downloadPath.trim();
  if (!path.startsWith('/')) path = '/$path';
  if (path.startsWith('/api/v1/')) {
    path = path.substring('/api/v1'.length);
  }
  return path;
}

String? validateTransparentDownloadPath({
  required String downloadPath,
  required String bookId,
  required String chapterId,
  required int pageNumber,
}) {
  if (downloadPath.isEmpty) {
    return 'Transparent page $pageNumber has no download path.';
  }
  final String lower = downloadPath.toLowerCase();
  if (lower.contains('://') ||
      lower.startsWith('http') ||
      downloadPath.contains('?') ||
      downloadPath.contains('#') ||
      lower.contains('token=')) {
    return 'Transparent page $pageNumber path is not allowed.';
  }
  if (lower.contains('/admin/') || lower.contains('/media/')) {
    return 'Transparent page $pageNumber path is not allowed.';
  }
  final String path = apiRelativeDownloadPath(downloadPath);
  final RegExp expected = RegExp(
    r'^/books/' +
        RegExp.escape(bookId) +
        r'/chapters/' +
        RegExp.escape(chapterId) +
        r'/transparent-pages/' +
        pageNumber.toString() +
        r'/?$',
  );
  if (!expected.hasMatch(path)) {
    return 'Transparent page $pageNumber path does not match the chapter.';
  }
  return null;
}
