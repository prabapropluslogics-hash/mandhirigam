import 'dart:typed_data';

/// Successful authenticated byte-range (or verified full) PDF payload.
class ByteRangeResponse {
  const ByteRangeResponse({
    required this.bytes,
    required this.statusCode,
    required this.start,
    required this.endInclusive,
    required this.totalSize,
    required this.fromPartialContent,
  });

  final Uint8List bytes;
  final int statusCode;

  /// Inclusive start offset of [bytes] within the full resource.
  final int start;

  /// Inclusive end offset of [bytes] within the full resource.
  final int endInclusive;

  /// Total resource size when known from Content-Range / Content-Length.
  final int totalSize;

  final bool fromPartialContent;

  int get length => bytes.length;
}

/// Parsed `bytes start-end/total` Content-Range header.
class ContentRangeHeader {
  const ContentRangeHeader({
    required this.start,
    required this.endInclusive,
    required this.total,
  });

  final int start;
  final int endInclusive;
  final int total;

  static ContentRangeHeader? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final Match? match =
        RegExp(r'bytes\s+(\d+)-(\d+)/(\d+|\*)', caseSensitive: false)
            .firstMatch(raw.trim());
    if (match == null) return null;
    final int start = int.tryParse(match.group(1)!) ?? -1;
    final int end = int.tryParse(match.group(2)!) ?? -1;
    final String totalRaw = match.group(3)!;
    final int total = totalRaw == '*' ? -1 : (int.tryParse(totalRaw) ?? -1);
    if (start < 0 || end < start) return null;
    return ContentRangeHeader(
      start: start,
      endInclusive: end,
      total: total,
    );
  }
}
