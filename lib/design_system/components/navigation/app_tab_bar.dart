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

/// Underline tab bar: gold label and indicator on the active tab, warm grey
/// labels otherwise, over a hairline divider.
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

  static const Duration _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final TextStyle base = AppTypography.label(context).copyWith(
      letterSpacing: 0.4,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.dividerFor(brightness),
            width: AppSizes.dividerThickness,
          ),
        ),
      ),
      child: Row(
        children: [
          for (final AppTabItem tab in tabs)
            Expanded(
              child: Semantics(
                selected: tab.value == selectedValue,
                child: InkWell(
                  onTap: () => onChanged(tab.value),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                          horizontal: AppSpacing.xs,
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: _duration,
                          style: base.copyWith(
                            color: tab.value == selectedValue
                                ? AppColors.brandPrimary
                                : AppColors.textSecondaryFor(brightness),
                          ),
                          child: Text(
                            tab.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: _duration,
                        height: AppSizes.tabIndicatorHeight,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        decoration: BoxDecoration(
                          color: tab.value == selectedValue
                              ? AppColors.brandPrimary
                              : AppColors.brandPrimary.withOpacity(0),
                          borderRadius: BorderRadius.circular(
                            AppSizes.tabIndicatorHeight,
                          ),
                          boxShadow: tab.value == selectedValue
                              ? [
                                  BoxShadow(
                                    color: AppColors.brandPrimary
                                        .withOpacity(0.45),
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
            ),
        ],
      ),
    );
  }
}
