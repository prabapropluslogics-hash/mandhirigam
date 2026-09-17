import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/errors/api_exception.dart';
import '../../core/utils/version_compare.dart';
import '../../data/models/announcement.dart';
import '../../data/models/app_config.dart';
import '../../data/repositories/app_config_repository.dart';

class AppConfigController extends ChangeNotifier {
  AppConfigController(this._repository);

  final AppConfigRepository _repository;

  AppConfig config = AppConfig.fallback;
  List<Announcement> announcements = const <Announcement>[];
  bool loading = false;
  bool loaded = false;
  String? errorMessage;
  AppUpdateKind updateKind = AppUpdateKind.none;
  String currentVersion = '1.0.0';

  bool get announcementsVisible =>
      config.features.announcementsEnabled && announcements.isNotEmpty;

  PlatformUpdateConfig get platformUpdate {
    if (!kIsWeb && Platform.isIOS) return config.appUpdate.ios;
    return config.appUpdate.android;
  }

  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (loaded && !force) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      try {
        final PackageInfo info = await PackageInfo.fromPlatform();
        currentVersion = info.version;
      } catch (_) {
        currentVersion = '1.0.0';
      }
      config = await _repository.loadConfig(force: force);
      if (config.features.announcementsEnabled) {
        announcements = await _repository.loadAnnouncements();
      } else {
        announcements = const <Announcement>[];
      }
      final PlatformUpdateConfig platform = platformUpdate;
      updateKind = resolveAppUpdate(
        currentVersion: currentVersion,
        latestVersion: platform.latestVersion,
        minimumVersion: platform.minimumVersion,
        forceUpdateEnabled: config.appUpdate.forceUpdateEnabled,
      );
      loaded = true;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Could not load app configuration.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
