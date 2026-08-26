import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/inputs/app_chip.dart';
import '../../../../design_system/components/inputs/app_slider.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/data/mock_catalog.dart';

class FilterSelection {
  const FilterSelection({
    this.access = 'Premium',
    this.genres = const <String>{'Fiction', 'Romance'},
    this.minRating = 4,
  });

  final String access;
  final Set<String> genres;
  final double minRating;

  FilterSelection copyWith({
    String? access,
    Set<String>? genres,
    double? minRating,
  }) {
    return FilterSelection(
      access: access ?? this.access,
      genres: genres ?? this.genres,
      minRating: minRating ?? this.minRating,
    );
  }

  static const FilterSelection initial = FilterSelection();
  static const FilterSelection reset = FilterSelection(
    access: 'Both',
    genres: <String>{},
    minRating: 0,
  );
}

Future<FilterSelection?> showFilterBottomSheet(
  BuildContext context, {
  FilterSelection initial = FilterSelection.initial,
}) {
  return showModalBottomSheet<FilterSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadii.bottomSheet),
      ),
    ),
    builder: (BuildContext context) {
      return FilterBottomSheet(initial: initial);
    },
  );
}

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key, this.initial = FilterSelection.initial});

  final FilterSelection initial;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterSelection _selection = widget.initial;

  void _toggleGenre(String genre) {
    final Set<String> next = Set<String>.from(_selection.genres);
    if (next.contains(genre)) {
      next.remove(genre);
    } else {
      next.add(genre);
    }
    setState(() => _selection = _selection.copyWith(genres: next));
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: AppInsets.lg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.bottomSheetHandleWidth,
              height: AppSizes.bottomSheetHandleHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
            const AppGap.lg(),
            Row(
              children: [
                Expanded(
                  child: Text('Filters', style: AppTypography.pageTitle(context)),
                ),
                AppTextButton(
                  label: 'Reset',
                  compact: true,
                  onPressed: () {
                    setState(() => _selection = FilterSelection.reset);
                  },
                ),
              ],
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text('Access', style: AppTypography.sectionTitle(context)),
                  const AppGap.md(),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final String access in <String>['Free', 'Premium', 'Both'])
                        AppChip(
                          label: access,
                          selected: _selection.access == access,
                          variant: _selection.access == access
                              ? AppChipVariant.goldOutline
                              : AppChipVariant.surface,
                          onTap: () {
                            setState(
                              () => _selection = _selection.copyWith(access: access),
                            );
                          },
                        ),
                    ],
                  ),
                  const AppGap.xxl(),
                  Text('Genre', style: AppTypography.sectionTitle(context)),
                  const AppGap.md(),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final String genre in MockCatalog.genres)
                        AppChip(
                          label: genre,
                          selected: _selection.genres.contains(genre),
                          variant: _selection.genres.contains(genre)
                              ? AppChipVariant.inverted
                              : AppChipVariant.surface,
                          onTap: () => _toggleGenre(genre),
                        ),
                    ],
                  ),
                  const AppGap.xxl(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Minimum rating',
                          style: AppTypography.sectionTitle(context),
                        ),
                      ),
                      Text(
                        '${_selection.minRating.toStringAsFixed(1)}+',
                        style: AppTypography.label(context),
                      ),
                    ],
                  ),
                  AppSlider(
                    value: _selection.minRating,
                    onChanged: (double value) {
                      setState(
                        () => _selection = _selection.copyWith(minRating: value),
                      );
                    },
                    label: '${_selection.minRating.toStringAsFixed(1)}+',
                  ),
                ],
              ),
            ),
            const AppGap.lg(),
            AppButton(
              label: 'Show 42 results',
              size: AppButtonSize.large,
              onPressed: () => Navigator.of(context).pop(_selection),
            ),
          ],
        ),
      ),
    );
  }
}
