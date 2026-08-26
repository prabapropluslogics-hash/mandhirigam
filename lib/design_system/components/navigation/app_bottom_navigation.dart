import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

class AppBottomNavDestination {
  const AppBottomNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Icon-only bottom navigation with a gold active indicator.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    this.destinations = const <AppBottomNavDestination>[
      AppBottomNavDestination(
        icon: AppIcons.homeOutline,
        selectedIcon: AppIcons.home,
        label: 'Home',
      ),
      AppBottomNavDestination(
        icon: AppIcons.search,
        selectedIcon: AppIcons.search,
        label: 'Search',
      ),
      AppBottomNavDestination(
        icon: AppIcons.library,
        selectedIcon: AppIcons.libraryFilled,
        label: 'Library',
      ),
      AppBottomNavDestination(
        icon: AppIcons.person,
        selectedIcon: AppIcons.person,
        label: 'Profile',
      ),
    ],
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<AppBottomNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Brightness brightness = Theme.of(context).brightness;

    return ColoredBox(
      color: AppColors.backgroundFor(brightness),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.bottomNavHeight,
          child: Row(
            children: [
              for (int i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == currentIndex,
                    color: i == currentIndex
                        ? colors.primary
                        : AppColors.textSecondaryFor(brightness),
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final AppBottomNavDestination destination;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: AppSizes.iconLg,
              color: color,
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? AppSizes.badgeDot : 0,
              height: selected ? AppSizes.badgeDot : 0,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}
