import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/catalog_book.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/widgets/access_badge.dart';
import '../../../../shared/widgets/network_book_cover.dart';
import '../../../../state/book_access.dart';
import '../../../../state/library_controller.dart';
import 'home_card_frame.dart';

/// Editorial card for one featured book: a blurred wash of the cover behind
/// the sharp cover, with title, real supporting text, access badge and CTA.
///
/// Fills the size given by its parent. The CTA label comes from [BookAccess];
/// tapping anywhere calls [onTap] (the existing Book Details route).
class FeaturedBookBanner extends StatelessWidget {
  const FeaturedBookBanner({
    super.key,
    required this.book,
    this.eyebrow,
    this.onTap,
  });

  final CatalogBook book;
  final String? eyebrow;
  final VoidCallback? onTap;

  static const double _coverAspect = 2 / 3;

  @override
  Widget build(BuildContext context) {
    final bool owned = context.watch<LibraryController>().owns(book.id);
    final BookAccess access = BookAccess.of(context, book);

    return HomeCardFrame(
      onTap: onTap,
      semanticLabel: book.title,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double coverHeight = constraints.maxHeight - AppSpacing.lg * 2;
          final double coverWidth = math.min(
            coverHeight * _coverAspect,
            constraints.maxWidth * 0.36,
          );
          final double titleSize =
              (constraints.maxWidth / 16).clamp(18.0, 24.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              _CoverWash(url: book.coverImage),
              const _Scrim(),
              Padding(
                padding: AppInsets.lg,
                child: Row(
                  children: [
                    _ElevatedCover(
                      book: book,
                      width: coverWidth,
                      height: coverWidth / _coverAspect,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _BookDetails(
                        book: book,
                        owned: owned,
                        eyebrow: eyebrow,
                        titleSize: titleSize,
                        ctaLabel: access.resolvingOwnership
                            ? 'Explore book'
                            : access.label,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Heavily blurred, low-resolution decode of the cover used as atmosphere.
class _CoverWash extends StatelessWidget {
  const _CoverWash({required this.url});

  final String? url;

  /// The wash is blurred anyway, so a tiny decode keeps memory low.
  static const int _decodeWidth = 96;

  @override
  Widget build(BuildContext context) {
    const Widget fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -0.1),
          radius: 1.1,
          colors: [
            AppColors.featuredEnd,
            AppColors.splashCharcoal,
            AppColors.splashBase,
          ],
          stops: [0, 0.5, 1],
        ),
      ),
    );
    final String? imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) return fallback;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 14,
        sigmaY: 14,
        tileMode: TileMode.clamp,
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        memCacheWidth: _decodeWidth,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Darkens toward the text side and adds a soft vignette for contrast.
class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.splashBase.withOpacity(0.3),
                AppColors.splashBase.withOpacity(0.72),
                AppColors.splashBase.withOpacity(0.9),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.4, -0.2),
              radius: 1.3,
              colors: [
                AppColors.splashDeep.withOpacity(0),
                AppColors.splashDeep.withOpacity(0.55),
              ],
              stops: const [0.45, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _ElevatedCover extends StatelessWidget {
  const _ElevatedCover({
    required this.book,
    required this.width,
    required this.height,
  });

  final CatalogBook book;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.coverBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWithOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: NetworkBookCover(
        book: book,
        width: width,
        height: height,
        showTitle: book.coverImage == null,
      ),
    );
  }
}

class _BookDetails extends StatelessWidget {
  const _BookDetails({
    required this.book,
    required this.owned,
    required this.eyebrow,
    required this.titleSize,
    required this.ctaLabel,
  });

  final CatalogBook book;
  final bool owned;
  final String? eyebrow;
  final double titleSize;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    final String byline = <String>[book.author, book.languageLabel]
        .where((String part) => part.trim().isNotEmpty)
        .join(' · ');
    final String description = book.description.trim();
    final TextStyle eyebrowStyle =
        Theme.of(context).textTheme.labelSmall!.copyWith(
              color: AppColors.brandAccent.withOpacity(0.8),
              letterSpacing: 1.6,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: eyebrow == null
                  ? const SizedBox.shrink()
                  : Text(
                      eyebrow!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: eyebrowStyle,
                    ),
            ),
            AccessBadge(book: book, owned: owned, compact: true),
          ],
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                flex: 3,
                child: Text(
                  book.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bookTitle(
                    context,
                    fontSize: titleSize,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              if (byline.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  byline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(context).copyWith(
                    color: AppColors.splashTagline.withOpacity(0.75),
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Flexible(
                  flex: 2,
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(context).copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CtaPill(label: ctaLabel),
      ],
    );
  }
}

class _CtaPill extends StatelessWidget {
  const _CtaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withOpacity(0.14),
        borderRadius: AppRadii.chipBorder,
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(0.55),
          width: AppSizes.borderThin,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: AppColors.brandAccent,
                      letterSpacing: 0.4,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            const Icon(
              AppIcons.chevronRight,
              size: AppSizes.iconSm,
              color: AppColors.brandAccent,
            ),
          ],
        ),
      ),
    );
  }
}
