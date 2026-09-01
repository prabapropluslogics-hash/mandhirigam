import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/icons/app_icons.dart';

class HighlightToolbar extends StatelessWidget {
  const HighlightToolbar({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.onNote,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback? onNote;

  static const List<Color> swatches = <Color>[
    AppColors.highlightYellow,
    AppColors.highlightGreen,
    AppColors.highlightBlue,
    AppColors.highlightInk,
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral800,
      elevation: 2,
      borderRadius: AppRadii.containerBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final Color color in swatches) ...[
              _Swatch(
                color: color,
                selected: color == selectedColor,
                onTap: () => onColorSelected(color),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            GestureDetector(
              onTap: onNote,
              child: const Icon(
                AppIcons.note,
                size: AppSizes.iconMd,
                color: AppColors.neutral100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: AppColors.neutral0, width: AppSizes.borderThick)
              : null,
        ),
        child: const SizedBox(
          width: AppSizes.highlightSwatch,
          height: AppSizes.highlightSwatch,
        ),
      ),
    );
  }
}
