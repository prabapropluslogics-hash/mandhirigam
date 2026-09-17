import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/library_item.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/async_body.dart';
import '../../../../shared/widgets/catalog_book_card.dart';
import '../../../../state/auth_controller.dart';
import '../../../../state/library_controller.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AuthController auth = context.watch<AuthController>();
    final LibraryController library = context.read<LibraryController>();
    if (!_requested && auth.isAuthenticated) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        library.load();
      });
    }
    if (!auth.isAuthenticated) {
      _requested = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final LibraryController library = context.watch<LibraryController>();

    return AppScaffold(
      safeAreaBottom: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.lg(),
          Padding(
            padding: AppInsets.pageHorizontal,
            child: Text('Library', style: AppTypography.pageTitle(context)),
          ),
          const AppGap.sm(),
          Padding(
            padding: AppInsets.pageHorizontal,
            child: Text(
              'Lifetime titles you have purchased.',
              style: AppTypography.helper(context),
            ),
          ),
          const AppGap.lg(),
          Expanded(
            child: !auth.isAuthenticated
                ? Center(
                    child: Padding(
                      padding: AppInsets.page,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sign in to see your library',
                            style: AppTypography.sectionTitle(context),
                            textAlign: TextAlign.center,
                          ),
                          const AppGap.md(),
                          AppButton(
                            label: 'Continue with Google',
                            isExpanded: false,
                            onPressed: () {
                              AppRouter.pushNamed(
                                context,
                                AppRoutes.login,
                                arguments: 'Sign in to open your library.',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : AsyncBody(
                    loading: library.loading && library.items.isEmpty,
                    errorMessage: library.errorMessage,
                    isEmpty: library.items.isEmpty,
                    onRetry: library.refresh,
                    emptyTitle: 'Your library is empty',
                    emptyMessage:
                        'Purchased books will appear here after payment is verified.',
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification notification) {
                        if (notification.metrics.pixels >
                            notification.metrics.maxScrollExtent - 240) {
                          library.loadMore();
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: library.refresh,
                        child: ListView.builder(
                          padding: AppInsets.pageHorizontal,
                          itemCount:
                              library.items.length + (library.loadingMore ? 1 : 0),
                          itemBuilder: (BuildContext context, int index) {
                            if (index >= library.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.lg),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final LibraryItem item = library.items[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CatalogBookCard(
                                  book: item.asBook,
                                  owned: true,
                                  onTap: () {
                                    AppRouter.pushNamed(
                                      context,
                                      AppRoutes.bookDetails,
                                      arguments: item.bookId,
                                    );
                                  },
                                ),
                                Text(
                                  '${item.entitlementType} · added ${_formatDate(item.grantedAt)}',
                                  style: AppTypography.caption(context),
                                ),
                                const AppGap.sm(),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    final DateTime? date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
