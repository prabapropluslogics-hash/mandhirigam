import 'package:flutter/material.dart';

import '../data/models/app_config.dart';
import '../data/repositories/app_config_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/books_repository.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/payments_repository.dart';
import '../data/services/app_config_api.dart';
import '../data/services/auth_api.dart';
import '../data/services/books_api.dart';
import '../data/services/google_auth_gateway.dart';
import '../data/services/library_api.dart';
import '../data/services/payments_api.dart';
import '../data/services/razorpay_checkout.dart';
import '../design_system/theme/app_colors.dart';
import '../state/app_config_controller.dart';
import '../state/auth_controller.dart';
import '../state/catalog_controller.dart';
import '../state/library_controller.dart';
import '../state/payment_controller.dart';
import 'errors/api_exception.dart';
import 'network/api_client.dart';
import 'storage/session_store.dart';
import 'utils/color_parse.dart';

class AppContainer {
  AppContainer({
    required this.apiClient,
    required this.sessionStore,
    required this.authController,
    required this.appConfigController,
    required this.catalogController,
    required this.libraryController,
    required this.paymentController,
    required this.booksRepository,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final AuthController authController;
  final AppConfigController appConfigController;
  final CatalogController catalogController;
  final LibraryController libraryController;
  final PaymentController paymentController;
  final BooksRepository booksRepository;

  static AppContainer create({
    ApiClient? apiClient,
    SessionStore? sessionStore,
    GoogleAuthGateway? googleAuth,
    CheckoutGateway? checkout,
  }) {
    final SessionStore store = sessionStore ?? SessionStore();
    late final AuthController auth;
    final ApiClient client = apiClient ??
        ApiClient(
          readAccessToken: store.readAccessToken,
          onUnauthorized: (ApiException error) => auth.handleUnauthorized(error),
        );
    auth = AuthController(
      AuthRepository(
        api: AuthApi(client),
        sessionStore: store,
        googleAuth: googleAuth ?? GoogleSignInGateway(),
      ),
    );
    final BooksRepository books = BooksRepository(BooksApi(client));
    return AppContainer(
      apiClient: client,
      sessionStore: store,
      authController: auth,
      appConfigController: AppConfigController(
        AppConfigRepository(
          configApi: AppConfigApi(client),
          announcementsApi: AnnouncementsApi(client),
        ),
      ),
      catalogController: CatalogController(books),
      libraryController: LibraryController(LibraryRepository(LibraryApi(client))),
      paymentController: PaymentController(
        PaymentsRepository(
          api: PaymentsApi(client),
          checkout: checkout ?? RazorpayCheckoutGateway(),
        ),
      ),
      booksRepository: books,
    );
  }

  BrandingColors brandingColors() {
    return BrandingColors.fromConfig(appConfigController.config.branding);
  }
}

class BrandingColors {
  const BrandingColors({
    required this.primary,
    required this.secondary,
    required this.button,
  });

  final Color primary;
  final Color secondary;
  final Color button;

  factory BrandingColors.fromConfig(BrandingConfig branding) {
    return BrandingColors(
      primary: parseHexColorOr(branding.primaryColor, AppColors.brandPrimary),
      secondary: parseHexColorOr(branding.secondaryColor, AppColors.brandSecondary),
      button: parseHexColorOr(branding.buttonColor, AppColors.brandPrimary),
    );
  }

  Color get onPrimary =>
      primary.computeLuminance() > 0.55 ? AppColors.textOnBrand : AppColors.neutral0;

  Color get onButton =>
      button.computeLuminance() > 0.55 ? AppColors.textOnBrand : AppColors.neutral0;
}
