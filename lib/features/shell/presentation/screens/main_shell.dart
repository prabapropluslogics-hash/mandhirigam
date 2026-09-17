import 'package:flutter/material.dart';

import '../../../../features/home/presentation/screens/home_screen.dart';
import '../../../../features/library/presentation/screens/library_screen.dart';
import '../../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../../features/search/presentation/screens/search_screen.dart';
import '../../../../design_system/components/navigation/app_bottom_navigation.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openSearch() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenSearch: _openSearch),
          SearchScreen(onCancel: () => setState(() => _index = 0)),
          const LibraryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _index,
        onChanged: (int index) => setState(() => _index = index),
      ),
    );
  }
}
