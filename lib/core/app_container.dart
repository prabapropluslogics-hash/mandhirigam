import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../data/models/app_config.dart';
import '../data/repositories/app_config_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/books_repository.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/payments_repository.dart';
import '../data/services/app_config_api.dart';
import '../data/services/auth_api.dart';
import '../data/services/books_api.dart';
import '../data/services/firebase_auth_gateway.dart';
import '../data/services/google_auth_gateway.dart';
import '../data/services/library_api.dart';
import '../data/services/payments_api.dart';
import '../data/services/razorpay_checkout.dart';
import '../design_system/theme/app_colors.dart';
import '../features/home/state/home_language_preference.dart';
import '../features/reader/state/reader_preferences.dart';
import '../services/deep_link_service.dart';
import '../services/local_preferences.dart';
import '../services/share_service.dart';
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
    required this.localPreferences,
    required this.readerPreferences,
    required this.homeLanguage,
    required this.shareService,
    required this.deepLinks,
  });

  final ApiClient apiClient;
  final SessionStore sessionStore;
  final AuthController authController;
  final AppConfigController appConfigController;
  final CatalogController catalogController;
  final LibraryController libraryController;
  final PaymentController paymentController;
  final BooksRepository booksRepository;
  final LocalPreferences localPreferences;
  final ReaderPreferences readerPreferences;
  final HomeLanguagePreference homeLanguage;
  final ShareService shareService;
  final DeepLinkService deepLinks;

  static AppContainer create({
    ApiClient? apiClient,
    http.Client? httpClient,
    SessionStore? sessionStore,
    GoogleAuthGateway? googleAuth,
    FirebaseAuthGateway? firebaseAuth,
    CheckoutGateway? checkout,
    LocalPreferences? localPreferences,
    DeepLinkSource? deepLinkSource,
  }) {
    final LocalPreferences preferences = localPreferences ?? LocalPreferences();
    final SessionStore store = sessionStore ?? SessionStore();
    late final AuthController auth;
    final ApiClient client = apiClient ??
        ApiClient(
          httpClient: httpClient,
          readAccessToken: store.readAccessToken,
          refreshAccessToken: () => auth.refreshAccessToken(),
          onUnauthorized: (ApiException error) => auth.handleUnauthorized(error),
        );
    auth = AuthController(
      AuthRepository(
        api: AuthApi(client),
        sessionStore: store,
        googleAuth: googleAuth ?? GoogleSignInGateway(),
        firebaseAuth: firebaseAuth ?? FirebaseAuthService(),
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
      localPreferences: preferences,
      readerPreferences: ReaderPreferences(preferences),
      homeLanguage: HomeLanguagePreference(preferences),
      shareService: ShareService(),
      deepLinks: DeepLinkService(
        preferences: preferences,
        source: deepLinkSource,
      ),
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
