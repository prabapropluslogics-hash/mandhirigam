import 'package:flutter/material.dart';

import '../../../../design_system/components/feedback/app_empty_state.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/navigation/app_bottom_navigation.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';

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
          const _NavPlaceholder(
            title: 'Library',
            message: 'Your shelves will appear here.',
          ),
          const _NavPlaceholder(
            title: 'Profile',
            message: 'Profile arrives with a later screen.',
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _index,
        onChanged: (int index) => setState(() => _index = index),
      ),
    );
  }
}

class _NavPlaceholder extends StatelessWidget {
  const _NavPlaceholder({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeAreaBottom: false,
      body: AppEmptyState(title: title, message: message),
    );
  }
}
