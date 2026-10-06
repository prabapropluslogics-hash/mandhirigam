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

/// Icon-only bottom navigation: muted inactive icons, a gold active icon with
/// a small glowing bar, on a deep surface separated by a gold hairline.
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
        selectedIcon: AppIcons.personFilled,
        label: 'Profile',
      ),
    ],
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<AppBottomNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppColors.splashBase : AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.brandPrimary.withOpacity(0.14),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWithOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
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
    required this.onTap,
  });

  static const Duration _duration = Duration(milliseconds: 200);
  static const double _indicatorWidth = 18;
  static const double _indicatorHeight = 3;

  final AppBottomNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? AppColors.brandPrimary
        : AppColors.textSecondaryDark.withOpacity(0.7);
    return Semantics(
      selected: selected,
      child: Tooltip(
        message: destination.label,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: _duration,
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  key: ValueKey<bool>(selected),
                  size: AppSizes.iconLg,
                  color: color,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedContainer(
                duration: _duration,
                curve: Curves.easeOutCubic,
                width: selected ? _indicatorWidth : 0,
                height: _indicatorHeight,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(_indicatorHeight),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.brandPrimary.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
