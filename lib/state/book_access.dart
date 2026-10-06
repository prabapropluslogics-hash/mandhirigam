import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/models/catalog_book.dart';
import 'app_config_controller.dart';
import 'auth_controller.dart';
import 'library_controller.dart';

enum BookAction { read, buy }

/// The primary action for a book, derived from the session, the book type and
/// the backend entitlement (library). Sign-in happens inside the action, so
/// the label never asks the user to sign in.
class BookAccess {
  const BookAccess._({
    required this.action,
    required this.requiresSignIn,
    this.resolvingOwnership = false,
  });

  factory BookAccess.resolve({
    required CatalogBook book,
    required bool authenticated,
    required bool owned,
    required bool guestCanReadFree,
    bool ownershipLoading = false,
  }) {
    if (!book.isPaid) {
      return BookAccess._(
        action: BookAction.read,
        requiresSignIn: !authenticated && !guestCanReadFree,
      );
    }
    if (authenticated && owned) {
      return const BookAccess._(action: BookAction.read, requiresSignIn: false);
    }
    return BookAccess._(
      action: BookAction.buy,
      requiresSignIn: !authenticated,
      resolvingOwnership: authenticated && ownershipLoading,
    );
  }

  /// Resolves from the app-wide controllers; rebuilds when they change.
  factory BookAccess.of(BuildContext context, CatalogBook book) {
    final AuthController auth = context.watch<AuthController>();
    final LibraryController library = context.watch<LibraryController>();
    final AppConfigController config = context.watch<AppConfigController>();
    return BookAccess.resolve(
      book: book,
      authenticated: auth.isAuthenticated,
      owned: library.owns(book.id),
      guestCanReadFree: config.config.guestAccess.allowGuestFreeBookReading,
      ownershipLoading: library.loading && !library.loaded,
    );
  }

  final BookAction action;
  final bool requiresSignIn;

  /// Paid book whose entitlement is still being fetched for this session;
  /// the CTA should wait instead of briefly offering "Buy now".
  final bool resolvingOwnership;

  bool get isRead => action == BookAction.read;

  String get label => isRead ? 'Read now' : 'Buy now';
}
