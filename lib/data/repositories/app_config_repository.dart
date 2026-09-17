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

  Future<AppConfig> loadConfig({bool force = false}) {
    if (force) {
      _configInFlight = null;
    }
    return _configInFlight ??= _configApi.fetch();
  }

  Future<List<Announcement>> loadAnnouncements() {
    return _announcementsApi.fetch();
  }
}
