import 'package:flutter/material.dart';

import '../../../../design_system/components/inputs/app_chip.dart';
import '../../../../design_system/components/inputs/app_slider.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/reading_prefs.dart';

Future<void> showReaderCustomizeSheet(
  BuildContext context, {
  required ReadingPrefs initial,
  required ValueChanged<ReadingPrefs> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadii.bottomSheet),
      ),
    ),
    builder: (BuildContext context) {
      return ReaderCustomizeSheet(initial: initial, onChanged: onChanged);
    },
  );
}

class ReaderCustomizeSheet extends StatefulWidget {
  const ReaderCustomizeSheet({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final ReadingPrefs initial;
  final ValueChanged<ReadingPrefs> onChanged;

  @override
  State<ReaderCustomizeSheet> createState() => _ReaderCustomizeSheetState();
}

class _ReaderCustomizeSheetState extends State<ReaderCustomizeSheet> {
  late ReadingPrefs _prefs = widget.initial;

  void _update(ReadingPrefs next) {
    setState(() => _prefs = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: AppInsets.lg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppSizes.bottomSheetHandleWidth,
                height: AppSizes.bottomSheetHandleHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
              ),
            ),
            const AppGap.xl(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  const _SectionLabel('READING MODE'),
                  const AppGap.md(),
                  Row(
                    children: [
                      for (final ReadingMode mode in ReadingMode.values) ...[
                        if (mode != ReadingMode.light)
                          const AppGap.sm(axis: AppGapAxis.horizontal),
                        Expanded(
                          child: _ModeCard(
                            mode: mode,
                            selected: _prefs.mode == mode,
                            onTap: () {
                              _update(_prefs.copyWith(mode: mode));
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const AppGap.xxl(),
                  const _SectionLabel('BRIGHTNESS'),
                  const AppGap.sm(),
                  Row(
                    children: [
                      const Icon(
                        AppIcons.sun,
                        size: AppSizes.iconSm,
                        color: AppColors.textSecondaryDark,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbColor: AppColors.neutral0,
                          ),
                          child: AppSlider(
                            value: _prefs.brightness,
                            min: 0.2,
                            max: 1,
                            divisions: 16,
                            onChanged: (double value) {
                              _update(_prefs.copyWith(brightness: value));
                            },
                          ),
                        ),
                      ),
                      const Icon(
                        AppIcons.sunFilled,
                        size: AppSizes.iconMd,
                        color: AppColors.textSecondaryDark,
                      ),
                    ],
                  ),
                  const AppGap.lg(),
                  const _SectionLabel('FONT SIZE'),
                  const AppGap.md(),
                  Row(
                    children: [
                      _SizeButton(
                        label: 'A',
                        fontSize: 14,
                        onTap: _prefs.fontSize <= 12
                            ? null
                            : () => _update(
                                  _prefs.copyWith(fontSize: _prefs.fontSize - 1),
                                ),
                      ),
                      Expanded(
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMutedDark,
                              borderRadius: AppRadii.containerBorder,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                '${_prefs.fontSize.round()}',
                                style: AppTypography.sectionTitle(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _SizeButton(
                        label: 'A',
                        fontSize: 22,
                        onTap: _prefs.fontSize >= 28
                            ? null
                            : () => _update(
                                  _prefs.copyWith(fontSize: _prefs.fontSize + 1),
                                ),
                      ),
                    ],
                  ),
                  const AppGap.xxl(),
                  const _SectionLabel('TYPEFACE'),
                  const AppGap.md(),
                  SizedBox(
                    height: AppSizes.chipHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: MockCatalog.typefaces.length,
                      separatorBuilder: (_, _) =>
                          const AppGap.sm(axis: AppGapAxis.horizontal),
                      itemBuilder: (BuildContext context, int index) {
                        final TypefaceOption option =
                            MockCatalog.typefaces[index];
                        final bool selected = option.id == _prefs.typefaceId;
                        return AppChip(
                          label: option.label,
                          selected: selected,
                          variant: selected
                              ? AppChipVariant.inverted
                              : AppChipVariant.surface,
                          onTap: () =>
                              _update(_prefs.copyWith(typefaceId: option.id)),
                        );
                      },
                    ),
                  ),
                  const AppGap.xxl(),
                  const _SectionLabel('LINE SPACING'),
                  const AppGap.md(),
                  Row(
                    children: [
                      for (final LineSpacing spacing in LineSpacing.values) ...[
                        if (spacing != LineSpacing.tight)
                          const AppGap.sm(axis: AppGapAxis.horizontal),
                        _SpacingButton(
                          spacing: spacing,
                          selected: _prefs.lineSpacing == spacing,
                          onTap: () =>
                              _update(_prefs.copyWith(lineSpacing: spacing)),
                        ),
                      ],
                    ],
                  ),
                  const AppGap.lg(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption(context).copyWith(
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ReadingMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = switch (mode) {
      ReadingMode.light => AppColors.neutral0,
      ReadingMode.sepia => AppColors.readingSepia,
      ReadingMode.dark => AppColors.neutral700,
    };
    final Color foreground = switch (mode) {
      ReadingMode.dark => AppColors.neutral0,
      ReadingMode.light => AppColors.textPrimary,
      ReadingMode.sepia => AppColors.readingSepiaInk,
    };
    final String label = switch (mode) {
      ReadingMode.light => 'Light',
      ReadingMode.sepia => 'Sepia',
      ReadingMode.dark => 'Dark',
    };

    return Material(
      color: background,
      borderRadius: AppRadii.containerBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.containerBorder,
        child: SizedBox(
          height: AppSizes.readingModeCardHeight,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Aa',
                      style: AppTypography.bookTitle(
                        context,
                        fontSize: 22,
                        color: foreground,
                      ),
                    ),
                    const AppGap.xs(),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foreground,
                          ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: Icon(
                    AppIcons.checkPlain,
                    size: AppSizes.iconSm,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.label,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMutedDark,
      borderRadius: AppRadii.containerBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.containerBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Text(
            label,
            style: AppTypography.bookTitle(
              context,
              fontSize: fontSize,
              color: onTap == null
                  ? AppColors.textDisabledDark
                  : AppColors.textPrimaryDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpacingButton extends StatelessWidget {
  const _SpacingButton({
    required this.spacing,
    required this.selected,
    required this.onTap,
  });

  final LineSpacing spacing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double gap = switch (spacing) {
      LineSpacing.tight => 3,
      LineSpacing.normal => 5,
      LineSpacing.relaxed => 8,
    };

    return Material(
      color: AppColors.surfaceMutedDark,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.containerBorder,
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: AppSizes.borderMedium,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.containerBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(height: gap),
                SizedBox(
                  width: 18,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.textPrimaryDark,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
