import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../features/home/presentation/screens/home_screen.dart';
import '../../../../features/library/presentation/screens/library_screen.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../../features/search/presentation/screens/search_screen.dart';
import '../../../../design_system/components/navigation/app_bottom_navigation.dart';
import '../../../../routing/back_navigation.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// A second system back on Home within this window exits the app.
  static const Duration exitWindow = Duration(seconds: 2);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  Timer? _exitArmed;

  @override
  void initState() {
    super.initState();
    BackNavigation.homeTabRequests.addListener(_showHome);
    BackNavigation.libraryTabRequests.addListener(_showLibrary);
  }

  @override
  void dispose() {
    _exitArmed?.cancel();
    BackNavigation.homeTabRequests.removeListener(_showHome);
    BackNavigation.libraryTabRequests.removeListener(_showLibrary);
    super.dispose();
  }

  void _openSearch() => setState(() => _index = 1);

  void _showHome() {
    if (mounted && _index != 0) setState(() => _index = 0);
  }

  void _showLibrary() {
    if (mounted && _index != 2) setState(() => _index = 2);
  }

  void _disarmExit() {
    _exitArmed?.cancel();
    _exitArmed = null;
  }

  /// System back: other tabs → Home tab; Home → confirm, then exit.
  void _onBack(bool didPop) {
    if (didPop) return;
    if (_index != 0) {
      _disarmExit();
      setState(() => _index = 0);
      return;
    }
    if (_exitArmed?.isActive ?? false) {
      _disarmExit();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }
    _exitArmed = Timer(MainShell.exitWindow, () => _exitArmed = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: MainShell.exitWindow,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _onBack,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(onOpenSearch: _openSearch),
            SearchScreen(onCancel: () => setState(() => _index = 0)),
            const LibraryScreen(),
            ProfileScreen(onOpenLibrary: () => setState(() => _index = 2)),
          ],
        ),
        bottomNavigationBar: AppBottomNavigation(
          currentIndex: _index,
          onChanged: (int index) => setState(() => _index = index),
        ),
      ),
    );
  }
}
