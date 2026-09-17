/// Backend envelope error preserved for UI and session handling.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  bool get isUnauthorized =>
      statusCode == 401 &&
      (code == 'TOKEN_EXPIRED' ||
          code == 'TOKEN_INVALID' ||
          code == 'UNAUTHENTICATED');

  bool get isAuthenticationRequired => code == 'AUTHENTICATION_REQUIRED';

  bool get isPurchaseRequired => code == 'PURCHASE_REQUIRED';

  bool get isAlreadyOwned => code == 'BOOK_ALREADY_OWNED';

  bool get isRateLimited => statusCode == 429 || code == 'RATE_LIMITED';

  bool get isPaymentNotCaptured => code == 'PAYMENT_NOT_CAPTURED';

  bool get isPaymentVerificationFailed =>
      code == 'PAYMENT_VERIFICATION_FAILED' ||
      code == 'INVALID_PAYMENT_SIGNATURE';

  String get userMessage {
    switch (code) {
      case 'TOKEN_EXPIRED':
      case 'TOKEN_INVALID':
      case 'UNAUTHENTICATED':
        return 'Please sign in again to continue.';
      case 'AUTHENTICATION_REQUIRED':
        return 'Sign in to read this book.';
      case 'PURCHASE_REQUIRED':
        return 'Purchase this book to continue reading.';
      case 'BOOK_ALREADY_OWNED':
        return 'You already own this book.';
      case 'PAYMENT_NOT_CAPTURED':
        return 'Payment is still processing. Please wait a moment.';
      case 'PAYMENT_VERIFICATION_FAILED':
      case 'INVALID_PAYMENT_SIGNATURE':
        return 'We could not confirm this payment. The book is not unlocked.';
      case 'RATE_LIMITED':
        return 'Too many attempts. Please wait and try again.';
      case 'USER_INACTIVE':
        return 'This account is inactive.';
      case 'GOOGLE_EMAIL_NOT_VERIFIED':
        return 'Your Google email is not verified.';
      case 'GOOGLE_ACCOUNT_CONFLICT':
        return 'This email is already linked to another Google account.';
      case 'GOOGLE_TOKEN_INVALID':
        return 'Google sign-in could not be verified. Please try again.';
      case 'BOOK_NOT_FOUND':
      case 'CHAPTER_NOT_FOUND':
        return 'This title is no longer available.';
      case 'NETWORK_ERROR':
        return 'Check your connection and try again.';
      case 'TIMEOUT':
        return 'The request timed out. Please try again.';
      default:
        return message.isEmpty ? 'Something went wrong. Please try again.' : message;
    }
  }

  @override
  String toString() => 'ApiException($statusCode $code: $message)';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'Network unavailable'})
      : super(statusCode: 0, code: 'NETWORK_ERROR');
}

class TimeoutApiException extends ApiException {
  const TimeoutApiException()
      : super(statusCode: 0, code: 'TIMEOUT', message: 'Request timed out');
}
