import '../models/announcement.dart';
import '../models/app_config.dart';
import '../services/app_config_api.dart';

class AppConfigRepository {
  AppConfigRepository({
    required AppConfigApi configApi,
    required AnnouncementsApi announcementsApi,
  })  : _configApi = configApi,
        _announcementsApi = announcementsApi;

  final AppConfigApi _configApi;
  final AnnouncementsApi _announcementsApi;

  Future<AppConfig>? _configInFlight;

  Future<AppConfig> loadConfig({bool force = false}) async {
    if (force) {
      _configInFlight = null;
    }
    final Future<AppConfig> pending =
        _configInFlight ??= _configApi.fetch();
    try {
      return await pending;
    } catch (_) {
      // Do not keep a failed Future — otherwise Retry never re-fetches.
      if (identical(_configInFlight, pending)) {
        _configInFlight = null;
      }
      rethrow;
    }
  }

  Future<List<Announcement>> loadAnnouncements() {
    return _announcementsApi.fetch();
  }
}
