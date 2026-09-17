import '../../core/network/api_client.dart';
import '../../core/utils/json_map.dart';
import '../models/announcement.dart';
import '../models/app_config.dart';

class AppConfigApi {
  AppConfigApi(this._client);

  final ApiClient _client;

  Future<AppConfig> fetch() async {
    final envelope = await _client.get('/app-config');
    return AppConfig.fromJson(asJsonMap(envelope.data));
  }
}

class AnnouncementsApi {
  AnnouncementsApi(this._client);

  final ApiClient _client;

  Future<List<Announcement>> fetch() async {
    final envelope = await _client.get('/announcements');
    return asJsonMapList(envelope.data).map(Announcement.fromJson).toList();
  }
}
