import 'package:flutter/foundation.dart';

import '../../../services/local_preferences.dart';
import '../presentation/widgets/home_language_selector.dart';

/// The Home content language, shared by the Home selector and Settings.
///
/// Tamil until the reader picks something else; the choice is kept on the
/// device. Only Home uses it, never the shared catalogue or Search.
class HomeLanguagePreference extends ChangeNotifier {
  HomeLanguagePreference(this._store);

  static const String _key = 'home.language';

  final LocalPreferences _store;

  HomeLanguage _language = HomeLanguage.initial;
  Future<void>? _loading;
  bool _changed = false;

  HomeLanguage get language => _language;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final String? code = await _store.read(_key);
    if (_changed || code == null) return;
    for (final HomeLanguage value in HomeLanguage.values) {
      if (value.code == code && value != _language) {
        _language = value;
        notifyListeners();
        return;
      }
    }
  }

  void select(HomeLanguage value) {
    _changed = true;
    if (value == _language) return;
    _language = value;
    notifyListeners();
    _store.write(_key, value.code);
  }
}
