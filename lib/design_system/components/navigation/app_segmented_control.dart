import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

class AppSegmentItem<T> {
  const AppSegmentItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Cream/dark segmented control used for payment methods and similar pickers.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<AppSegmentItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedFor(brightness),
        borderRadius: AppRadii.chipBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            for (final AppSegmentItem<T> item in items)
              Expanded(
                child: _Segment(
                  item: item,
                  selected: item.value == selected,
                  onTap: () => onChanged(item.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppSegmentItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground =
        selected ? AppColors.textPrimary : AppColors.textSecondaryDark;

    return Material(
      color: selected ? AppColors.neutral50 : Colors.transparent,
      borderRadius: AppRadii.chipBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.chipBorder,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.buttonHeightMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: AppSizes.iconMd, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
