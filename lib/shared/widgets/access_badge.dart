import 'package:flutter/material.dart';

import '../../core/utils/money_format.dart';
import '../../data/models/catalog_book.dart';
import '../../design_system/icons/app_icons.dart';
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
    final String label =
        owned ? 'OWNED' : (book.isFree ? 'FREE' : book.priceLabel);
    // Paid: solid gold. Owned: soft gold with a check. Free: dark pill with a
    // gold hairline. The border is painted, so it never changes the size.
    final bool paid = !owned && !book.isFree;
    final Color background = paid
        ? AppColors.brandPrimary
        : owned
            ? AppColors.brandPrimary.withOpacity(0.16)
            : AppColors.surfaceDark.withOpacity(0.85);
    final Color foreground = paid
        ? AppColors.textOnBrand
        : owned
            ? AppColors.brandAccent
            : AppColors.splashTagline;
    final TextStyle? style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.chipBorder,
        border: paid
            ? null
            : Border.all(
                color: AppColors.brandPrimary.withOpacity(owned ? 0.6 : 0.45),
                width: 0.8,
              ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        child: owned
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.checkFilled,
                    size: compact ? 11 : 13,
                    color: foreground,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(label, style: style),
                ],
              )
            : Text(label, style: style),
      ),
    );
  }
}

class PriceLabel extends StatelessWidget {
  const PriceLabel(
      {super.key, required this.minorUnits, this.currency = 'INR'});

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
