import 'package:flutter/material.dart';

/// Centralized icon references.
///
/// Prefer this over scattering raw [Icons] usages when the same glyph is reused.
/// Replace entries with custom asset icons as brand assets arrive.
abstract final class AppIcons {
  static const IconData home = Icons.home_outlined;
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData settings = Icons.settings_outlined;
  static const IconData person = Icons.person_outline_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData empty = Icons.inbox_outlined;
  static const IconData check = Icons.check_circle_outline_rounded;
}
