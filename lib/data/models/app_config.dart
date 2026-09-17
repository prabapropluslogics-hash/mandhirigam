import '../../core/utils/json_map.dart';
import 'catalog_book.dart';

class AppConfig {
  const AppConfig({
    required this.version,
    required this.branding,
    required this.home,
    required this.catalogue,
    required this.guestAccess,
    required this.features,
    required this.appUpdate,
  });

  final int version;
  final BrandingConfig branding;
  final HomeConfig home;
  final CatalogueConfig catalogue;
  final GuestAccessConfig guestAccess;
  final FeatureFlags features;
  final AppUpdateConfig appUpdate;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      version: asInt(json['version']),
      branding: BrandingConfig.fromJson(
        json['branding'] is Map ? asJsonMap(json['branding']) : const <String, dynamic>{},
      ),
      home: HomeConfig.fromJson(
        json['home'] is Map ? asJsonMap(json['home']) : const <String, dynamic>{},
      ),
      catalogue: CatalogueConfig.fromJson(
        json['catalogue'] is Map ? asJsonMap(json['catalogue']) : const <String, dynamic>{},
      ),
      guestAccess: GuestAccessConfig.fromJson(
        json['guestAccess'] is Map
            ? asJsonMap(json['guestAccess'])
            : const <String, dynamic>{},
      ),
      features: FeatureFlags.fromJson(
        json['features'] is Map ? asJsonMap(json['features']) : const <String, dynamic>{},
      ),
      appUpdate: AppUpdateConfig.fromJson(
        json['appUpdate'] is Map ? asJsonMap(json['appUpdate']) : const <String, dynamic>{},
      ),
    );
  }

  static const AppConfig fallback = AppConfig(
    version: 0,
    branding: BrandingConfig.fallback,
    home: HomeConfig.fallback,
    catalogue: CatalogueConfig.fallback,
    guestAccess: GuestAccessConfig.fallback,
    features: FeatureFlags.fallback,
    appUpdate: AppUpdateConfig.fallback,
  );
}

class BrandingConfig {
  const BrandingConfig({
    required this.appName,
    required this.tagline,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.buttonColor,
  });

  final String appName;
  final String tagline;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? buttonColor;

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    return BrandingConfig(
      appName: asString(json['appName'], 'Mantirigam'),
      tagline: asString(json['tagline']),
      logoUrl: asStringOrNull(json['logoUrl']),
      primaryColor: asStringOrNull(json['primaryColor']),
      secondaryColor: asStringOrNull(json['secondaryColor']),
      buttonColor: asStringOrNull(json['buttonColor']),
    );
  }

  static const BrandingConfig fallback = BrandingConfig(
    appName: 'Mantirigam',
    tagline: '',
  );
}

class HomeConfig {
  const HomeConfig({
    required this.showHero,
    required this.heroTitle,
    required this.heroSubtitle,
    this.heroImageUrl,
    required this.showFeaturedBooks,
    required this.featuredBooks,
    required this.showContinueReading,
    required this.showCategories,
    required this.showLatestBooks,
  });

  final bool showHero;
  final String heroTitle;
  final String heroSubtitle;
  final String? heroImageUrl;
  final bool showFeaturedBooks;
  final List<FeaturedBookRef> featuredBooks;
  final bool showContinueReading;
  final bool showCategories;
  final bool showLatestBooks;

  factory HomeConfig.fromJson(Map<String, dynamic> json) {
    return HomeConfig(
      showHero: asBool(json['showHero'], true),
      heroTitle: asString(json['heroTitle']),
      heroSubtitle: asString(json['heroSubtitle']),
      heroImageUrl: asStringOrNull(json['heroImageUrl']),
      showFeaturedBooks: asBool(json['showFeaturedBooks'], true),
      featuredBooks: asJsonMapList(json['featuredBooks'])
          .map(FeaturedBookRef.fromJson)
          .where((FeaturedBookRef book) => book.id.isNotEmpty)
          .toList(growable: false),
      showContinueReading: asBool(json['showContinueReading'], true),
      showCategories: asBool(json['showCategories'], true),
      showLatestBooks: asBool(json['showLatestBooks'], true),
    );
  }

  static const HomeConfig fallback = HomeConfig(
    showHero: true,
    heroTitle: '',
    heroSubtitle: '',
    showFeaturedBooks: true,
    featuredBooks: <FeaturedBookRef>[],
    showContinueReading: false,
    showCategories: true,
    showLatestBooks: true,
  );
}

class CatalogueConfig {
  const CatalogueConfig({
    required this.showLanguageFilter,
    required this.showFreeBooks,
    required this.showPaidBooks,
    required this.defaultLanguage,
  });

  final bool showLanguageFilter;
  final bool showFreeBooks;
  final bool showPaidBooks;
  final String defaultLanguage;

  factory CatalogueConfig.fromJson(Map<String, dynamic> json) {
    return CatalogueConfig(
      showLanguageFilter: asBool(json['showLanguageFilter'], true),
      showFreeBooks: asBool(json['showFreeBooks'], true),
      showPaidBooks: asBool(json['showPaidBooks'], true),
      defaultLanguage: asString(json['defaultLanguage'], 'all'),
    );
  }

  static const CatalogueConfig fallback = CatalogueConfig(
    showLanguageFilter: true,
    showFreeBooks: true,
    showPaidBooks: true,
    defaultLanguage: 'all',
  );
}

class GuestAccessConfig {
  const GuestAccessConfig({
    required this.allowGuestFreeBookReading,
    required this.allowPaidBookPreview,
  });

  final bool allowGuestFreeBookReading;
  final bool allowPaidBookPreview;

  factory GuestAccessConfig.fromJson(Map<String, dynamic> json) {
    return GuestAccessConfig(
      allowGuestFreeBookReading: asBool(json['allowGuestFreeBookReading']),
      allowPaidBookPreview: false,
    );
  }

  static const GuestAccessConfig fallback = GuestAccessConfig(
    allowGuestFreeBookReading: false,
    allowPaidBookPreview: false,
  );
}

class FeatureFlags {
  const FeatureFlags({
    required this.bookmarksEnabled,
    required this.readingProgressEnabled,
    required this.continueReadingEnabled,
    required this.announcementsEnabled,
    required this.featuredBooksEnabled,
  });

  final bool bookmarksEnabled;
  final bool readingProgressEnabled;
  final bool continueReadingEnabled;
  final bool announcementsEnabled;
  final bool featuredBooksEnabled;

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      bookmarksEnabled: asBool(json['bookmarksEnabled']),
      readingProgressEnabled: asBool(json['readingProgressEnabled']),
      continueReadingEnabled: asBool(json['continueReadingEnabled']),
      announcementsEnabled: asBool(json['announcementsEnabled'], true),
      featuredBooksEnabled: asBool(json['featuredBooksEnabled'], true),
    );
  }

  static const FeatureFlags fallback = FeatureFlags(
    bookmarksEnabled: false,
    readingProgressEnabled: false,
    continueReadingEnabled: false,
    announcementsEnabled: true,
    featuredBooksEnabled: true,
  );
}

class PlatformUpdateConfig {
  const PlatformUpdateConfig({
    this.latestVersion,
    this.minimumVersion,
    this.storeUrl,
  });

  final String? latestVersion;
  final String? minimumVersion;
  final String? storeUrl;

  factory PlatformUpdateConfig.fromJson(Map<String, dynamic> json) {
    return PlatformUpdateConfig(
      latestVersion: asStringOrNull(json['latestVersion']),
      minimumVersion: asStringOrNull(json['minimumVersion']),
      storeUrl: asStringOrNull(json['storeUrl']),
    );
  }

  static const PlatformUpdateConfig empty = PlatformUpdateConfig();
}

class AppUpdateConfig {
  const AppUpdateConfig({
    required this.android,
    required this.ios,
    required this.forceUpdateEnabled,
    required this.updateMessage,
  });

  final PlatformUpdateConfig android;
  final PlatformUpdateConfig ios;
  final bool forceUpdateEnabled;
  final String updateMessage;

  factory AppUpdateConfig.fromJson(Map<String, dynamic> json) {
    return AppUpdateConfig(
      android: json['android'] is Map
          ? PlatformUpdateConfig.fromJson(asJsonMap(json['android']))
          : PlatformUpdateConfig.empty,
      ios: json['ios'] is Map
          ? PlatformUpdateConfig.fromJson(asJsonMap(json['ios']))
          : PlatformUpdateConfig.empty,
      forceUpdateEnabled: asBool(json['forceUpdateEnabled']),
      updateMessage: asString(json['updateMessage']),
    );
  }

  static const AppUpdateConfig fallback = AppUpdateConfig(
    android: PlatformUpdateConfig.empty,
    ios: PlatformUpdateConfig.empty,
    forceUpdateEnabled: false,
    updateMessage: '',
  );
}
