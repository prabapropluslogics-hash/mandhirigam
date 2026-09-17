import 'package:flutter/material.dart';

import '../../core/utils/money_format.dart';
import '../../data/models/catalog_book.dart';
import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_radii.dart';
import '../../design_system/theme/app_spacing.dart';

class AccessBadge extends StatelessWidget {
  const AccessBadge({
    super.key,
    required this.book,
    this.owned = false,
    this.compact = false,
  });

  final CatalogBook book;
  final bool owned;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String label = owned
        ? 'OWNED'
        : (book.isFree ? 'FREE' : book.priceLabel);
    final Color background = owned
        ? AppColors.success
        : (book.isFree ? AppColors.surfaceElevatedDark : AppColors.brandPrimary);
    final Color foreground =
        owned || book.isFree ? AppColors.neutral0 : AppColors.textOnBrand;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.chipBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class PriceLabel extends StatelessWidget {
  const PriceLabel({super.key, required this.minorUnits, this.currency = 'INR'});

  final int minorUnits;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatMoney(minorUnits: minorUnits, currency: currency),
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
