import 'package:flutter/material.dart';

import '../../../../design_system/components/inputs/app_search_bar.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_spacing.dart';

/// Read-only search field on Home that hands off to the Search tab.
class HomeSearchEntry extends StatelessWidget {
  const HomeSearchEntry({super.key, required this.onTap});

  static const double _height = 54;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadii.searchBarBorder,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceMutedDark, AppColors.surfaceDark],
          ),
          border: Border.all(
            color: AppColors.brandPrimary.withOpacity(0.2),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowWithOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              fillColor: AppColors.surfaceDark.withOpacity(0),
              prefixIconColor: AppColors.brandPrimary,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
          child: GestureDetector(
            onTap: onTap,
            child: const AbsorbPointer(
              child: AppSearchBar(
                readOnly: true,
                hintText: 'Search books',
                height: _height,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
