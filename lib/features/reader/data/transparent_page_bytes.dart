import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/models/transparent_pages.dart';

/// Checks a downloaded page before it can be decoded.
///
/// Throws [ApiException] for status, type, length, and checksum failures.
/// The caller still has to decode the PNG and compare pixel dimensions.
void verifyTransparentPageBytes({
  required TransparentPage page,
  required Uint8List bytes,
  required String? contentType,
  int? contentLengthHeader,
  required int statusCode,
}) {
  if (statusCode == 304) {
    throw const ApiException(
      statusCode: 304,
      code: 'NOT_MODIFIED',
      message: 'Transparent page was not downloaded.',
    );
  }
  if (statusCode != 200) {
    throw ApiException(
      statusCode: statusCode,
      code: 'MALFORMED_RESPONSE',
      message: 'Transparent page request failed.',
    );
  }
  final String type = (contentType ?? '').toLowerCase();
  final String mime = type.split(';').first.trim();
  if (mime != 'image/png') {
    throw const ApiException(
      statusCode: 200,
      code: 'MALFORMED_RESPONSE',
      message: 'Transparent page was not a PNG.',
    );
  }
  if (contentLengthHeader != null && contentLengthHeader != bytes.length) {
    throw const ApiException(
      statusCode: 200,
      code: 'MALFORMED_RESPONSE',
      message: 'Transparent page length does not match the response.',
    );
  }
  if (bytes.length != page.size) {
    throw ApiException(
      statusCode: 200,
      code: 'PAGE_SIZE_MISMATCH',
      message: 'Transparent page ${page.pageNumber} length does not match.',
    );
  }
  if (bytes.length < 8 ||
      bytes[0] != 0x89 ||
      bytes[1] != 0x50 ||
      bytes[2] != 0x4E ||
      bytes[3] != 0x47) {
    throw const ApiException(
      statusCode: 200,
      code: 'MALFORMED_RESPONSE',
      message: 'Transparent page is not a PNG.',
    );
  }
  final String digest = sha256.convert(bytes).toString();
  if (digest != page.sha256) {
    throw ApiException(
      statusCode: 200,
      code: 'PAGE_CHECKSUM_MISMATCH',
      message: 'Transparent page ${page.pageNumber} checksum does not match.',
    );
  }
}

/// A page may be painted only for its own identity.
bool transparentImageBelongsToPage({
  required int imagePage,
  required int widgetPage,
  required String imageIdentity,
  required String widgetIdentity,
  required bool closed,
}) {
  return !closed &&
      imagePage == widgetPage &&
      imageIdentity.isNotEmpty &&
      imageIdentity == widgetIdentity;
}

/// True when a failed page may offer the Original PDF reader.
///
/// Entitlement and authentication failures stay on this route. They are not
/// sent to the PDF download as another way to fetch the chapter.
bool transparentFailureOffersPdf(Object error) {
  if (error is ApiException) {
    if (error.isPurchaseRequired ||
        error.isForbidden ||
        error.isUnauthorized ||
        error.isAuthenticationRequired) {
      return false;
    }
  }
  return true;
}
