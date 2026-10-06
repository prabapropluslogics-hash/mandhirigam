import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Applies the Maanthirigam token theme (charcoal + muted gold) to a subtree,
/// independent of the admin-configured branding colours that drive the
/// app-wide theme.
class BrandTheme extends StatelessWidget {
  const BrandTheme({super.key, required this.child});

  static final ThemeData _dark = AppTheme.dark();
  static final ThemeData _light = AppTheme.light();

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Theme(data: dark ? _dark : _light, child: child);
  }
}
