import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/access_badge.dart';
import '../../../../design_system/components/feedback/premium_badge.dart';
import '../../../../design_system/components/feedback/rating_view.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/navigation/app_tab_bar.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/widgets/book_cover.dart';
import '../widgets/book_info_item.dart';
import '../widgets/bottom_action_bar.dart';

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  String _tab = 'overview';
  bool _expanded = false;
  bool _favorited = false;

  @override
  Widget build(BuildContext context) {
    final Book book = MockCatalog.byId(widget.bookId);
    final String visibleDescription = _expanded
        ? book.description
        : (book.description.length > 140
            ? '${book.description.substring(0, 140).trim()}… '
            : book.description);

    return AppScaffold(
      safeAreaBottom: false,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                Padding(
                  padding: AppInsets.pageHorizontal,
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: AppIcons.back,
                        tooltip: 'Back',
                        onPressed: () => AppRouter.pop(context),
                      ),
                      const Spacer(),
                      AppIconButton(
                        icon: _favorited
                            ? AppIcons.favoriteFilled
                            : AppIcons.favorite,
                        tooltip: 'Favorite',
                        onPressed: () => setState(() => _favorited = !_favorited),
                      ),
                      AppIconButton(
                        icon: AppIcons.share,
                        tooltip: 'Share',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const AppGap.md(),
                Center(
                  child: BookCover(
                    book: book,
                    width: AppSizes.bookCoverWidthLg,
                    height: AppSizes.bookCoverHeightLg,
                    showTitle: true,
                  ),
                ),
                const AppGap.xl(),
                Padding(
                  padding: AppInsets.pageHorizontal,
                  child: Column(
                    children: [
                      Text(
                        book.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.bookTitle(context, fontSize: 26),
                      ),
                      const AppGap.xs(),
                      Text(
                        'by ${book.author}',
                        style: AppTypography.helper(context),
                      ),
                      const AppGap.md(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (book.isPremium)
                            const PremiumBadge()
                          else
                            const AccessBadge.free(),
                          const AppGap.md(axis: AppGapAxis.horizontal),
                          RatingView(
                            rating: book.rating,
                            reviewCountLabel: book.reviewCountLabel,
                          ),
                        ],
                      ),
                      const AppGap.xxl(),
                      BookInfoRow(
                        pages: '${book.pages}',
                        readTime: book.readTime,
                        language: book.language,
                      ),
                    ],
                  ),
                ),
                const AppGap.lg(),
                AppTabBar(
                  selectedValue: _tab,
                  onChanged: (String value) => setState(() => _tab = value),
                  tabs: const <AppTabItem>[
                    AppTabItem(label: 'Overview', value: 'overview'),
                    AppTabItem(label: 'Chapters', value: 'chapters'),
                    AppTabItem(label: 'Reviews', value: 'reviews'),
                  ],
                ),
                Padding(
                  padding: AppInsets.page,
                  child: _tabContent(context, book, visibleDescription),
                ),
              ],
            ),
          ),
          if (book.isPremium)
            BottomActionBar(
              onFreeSample: () {
                AppRouter.pushNamed(
                  context,
                  AppRoutes.reader,
                  arguments: book.id,
                );
              },
              onUnlockPremium: () {
                AppRouter.pushNamed(context, AppRoutes.subscription);
              },
            )
          else
            BottomActionBar.startReading(
              onStartReading: () {
                AppRouter.pushNamed(
                  context,
                  AppRoutes.reader,
                  arguments: book.id,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _tabContent(BuildContext context, Book book, String visibleDescription) {
    if (_tab == 'chapters') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < book.chapters.length; i++) ...[
            Text(
              '${i + 1}. ${book.chapters[i]}',
              style: AppTypography.body(context),
            ),
            const AppGap.sm(),
          ],
        ],
      );
    }

    if (_tab == 'reviews') {
      return Text(
        'Readers praise ${book.title} for its atmosphere and restraint.',
        style: AppTypography.body(context),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: AppTypography.body(context),
            children: [
              TextSpan(text: visibleDescription),
              if (!_expanded && book.description.length > 140)
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => setState(() => _expanded = true),
                    child: Text(
                      'Read more',
                      style: AppTypography.label(context).copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const AppGap.xxl(),
        Text('Chapters', style: AppTypography.sectionTitle(context)),
        const AppGap.md(),
        for (int i = 0; i < book.chapters.take(4).length; i++) ...[
          Text(
            '${i + 1}. ${book.chapters[i]}',
            style: AppTypography.bodySmall(context),
          ),
          const AppGap.sm(),
        ],
      ],
    );
  }
}
