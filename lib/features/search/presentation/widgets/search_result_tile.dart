import 'package:flutter/material.dart';

import '../../../../data/models/catalog_book.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/widgets/access_badge.dart';
import '../../../../shared/widgets/network_book_cover.dart';

/// Compact search result: shadowed cover, serif title, author · language and
/// the access badge.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.book,
    required this.owned,
    required this.onTap,
  });

  static const double _coverWidth = 60;
  static const double _coverHeight = 88;

  final CatalogBook book;
  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius coverRadius = BorderRadius.circular(AppRadii.xs + 2);
    final String author = book.author.trim();
    final String meta = <String>[
      if (author.isNotEmpty) author,
      if (book.languageLabel.trim().isNotEmpty) book.languageLabel,
    ].join(' · ');

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        highlightColor: AppColors.brandPrimary.withOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: coverRadius,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowWithOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    NetworkBookCover(
                      book: book,
                      width: _coverWidth,
                      height: _coverHeight,
                      showTitle: book.coverImage == null,
                      borderRadius: coverRadius,
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: coverRadius,
                            border: Border.all(
                              color: AppColors.splashTagline.withOpacity(0.08),
                              width: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bookTitle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryDark,
                      ).copyWith(height: 1.35),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(context).copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    AccessBadge(book: book, owned: owned, compact: true),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                AppIcons.chevronRight,
                size: AppSizes.iconMd,
                color: AppColors.brandPrimary.withOpacity(0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
