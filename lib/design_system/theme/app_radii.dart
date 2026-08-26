import 'package:flutter/painting.dart';

/// Corner radius tokens and semantic aliases.
///
/// Prefer semantic getters ([button], [card], [textField], …) in components.
abstract final class AppRadii {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  // Semantic aliases (change once when design specs refine)
  static const double button = sm;
  static const double textField = sm;
  static const double card = md;
  static const double dialog = lg;
  static const double container = md;
  static const double chip = full;
  static const double iconButton = full;

  static BorderRadius get buttonBorder => BorderRadius.circular(button);
  static BorderRadius get textFieldBorder => BorderRadius.circular(textField);
  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get dialogBorder => BorderRadius.circular(dialog);
  static BorderRadius get containerBorder => BorderRadius.circular(container);
}
