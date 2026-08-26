import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppTabItem {
  const AppTabItem({required this.label, required this.value});

  final String label;
  final String value;
}

/// Underline tab bar matching the book-details reference.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<AppTabItem> tabs;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (final AppTabItem tab in tabs)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(tab.value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      tab.label,
                      textAlign: TextAlign.center,
                      style: AppTypography.label(context).copyWith(
                        color: tab.value == selectedValue
                            ? AppColors.textPrimaryFor(
                                Theme.of(context).brightness,
                              )
                            : AppColors.textSecondaryFor(
                                Theme.of(context).brightness,
                              ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: AppSizes.tabIndicatorHeight,
                    color: tab.value == selectedValue
                        ? colors.primary
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
