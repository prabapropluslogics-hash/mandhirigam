import 'package:flutter/foundation.dart';

import '../../../services/local_preferences.dart';

enum ReaderThemeMode {
  olaichuvadi('olaichuvadi', 'Olaichuvadi'),
  dark('dark', 'Dark'),
  light('light', 'Light');

  const ReaderThemeMode(this.code, this.label);

  final String code;
  final String label;
}

enum ReaderLineHeight {
  compact('compact', 'Compact', 1.55),
  comfortable('comfortable', 'Comfortable', 1.75),
  spacious('spacious', 'Spacious', 2.05);

  const ReaderLineHeight(this.code, this.label, this.factor);

  final String code;
  final String label;
  final double factor;
}

enum ReaderWidth {
  narrow('narrow', 'Narrow', 560, 40),
  standard('standard', 'Standard', 680, 26),
  wide('wide', 'Wide', 880, 20);

  const ReaderWidth(this.code, this.label, this.maxWidth, this.sidePadding);

  final String code;
  final String label;

  /// Widest text column on large screens.
  final double maxWidth;

  /// Space between the screen edge and the text on phones.
  final double sidePadding;
}

/// Reader display settings. Stored on the device only.
class ReaderPreferences extends ChangeNotifier {
  ReaderPreferences(this._store);

  static const double minFontSize = 14;
  static const double maxFontSize = 28;
  static const double defaultFontSize = 17;

  static const String _fontSizeKey = 'reader.fontSize';
  static const String _lineHeightKey = 'reader.lineHeight';
  static const String _themeKey = 'reader.theme';
  static const String _widthKey = 'reader.width';

  final LocalPreferences _store;

  double _fontSize = defaultFontSize;
  ReaderLineHeight _lineHeight = ReaderLineHeight.comfortable;
  ReaderThemeMode _theme = ReaderThemeMode.olaichuvadi;
  ReaderWidth _width = ReaderWidth.standard;

  Future<void>? _loading;
  int _revision = 0;

  double get fontSize => _fontSize;
  ReaderLineHeight get lineHeight => _lineHeight;
  ReaderThemeMode get theme => _theme;
  ReaderWidth get width => _width;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final int revision = _revision;
    final String? size = await _store.read(_fontSizeKey);
    final String? height = await _store.read(_lineHeightKey);
    final String? theme = await _store.read(_themeKey);
    final String? width = await _store.read(_widthKey);
    if (revision != _revision) return;
    final double? parsedSize = size == null ? null : double.tryParse(size);
    if (parsedSize != null) {
      _fontSize = parsedSize.clamp(minFontSize, maxFontSize).toDouble();
    }
    _lineHeight = _byCode(ReaderLineHeight.values, height, _lineHeight,
        (ReaderLineHeight v) => v.code);
    _theme = _byCode(
        ReaderThemeMode.values, theme, _theme, (ReaderThemeMode v) => v.code);
    _width =
        _byCode(ReaderWidth.values, width, _width, (ReaderWidth v) => v.code);
    notifyListeners();
  }

  /// Updates the size while the slider moves; call [commitFontSize] when the
  /// drag ends so storage is written once.
  void setFontSize(double value) {
    final double next = value.clamp(minFontSize, maxFontSize).roundToDouble();
    if (next == _fontSize) return;
    _revision++;
    _fontSize = next;
    notifyListeners();
  }

  void commitFontSize() {
    _store.write(_fontSizeKey, _fontSize.toStringAsFixed(0));
  }

  void setLineHeight(ReaderLineHeight value) {
    if (value == _lineHeight) return;
    _revision++;
    _lineHeight = value;
    notifyListeners();
    _store.write(_lineHeightKey, value.code);
  }

  void setTheme(ReaderThemeMode value) {
    if (value == _theme) return;
    _revision++;
    _theme = value;
    notifyListeners();
    _store.write(_themeKey, value.code);
  }

  void setWidth(ReaderWidth value) {
    if (value == _width) return;
    _revision++;
    _width = value;
    notifyListeners();
    _store.write(_widthKey, value.code);
  }

  static T _byCode<T>(
    List<T> values,
    String? code,
    T fallback,
    String Function(T) codeOf,
  ) {
    if (code == null) return fallback;
    for (final T value in values) {
      if (codeOf(value) == code) return value;
    }
    return fallback;
  }
}
