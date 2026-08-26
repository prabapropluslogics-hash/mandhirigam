import 'package:flutter/material.dart';

/// App-level scaffold wrapper for consistent structure across screens.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.useSafeArea = true,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final bool useSafeArea;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    final Widget resolvedBody = useSafeArea
        ? SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: body)
        : body;

    return Scaffold(
      appBar: appBar,
      body: resolvedBody,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor,
    );
  }
}
