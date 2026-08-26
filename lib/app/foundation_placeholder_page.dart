import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../design_system/components/layout/app_gap.dart';
import '../design_system/components/layout/app_page_padding.dart';
import '../design_system/components/layout/app_scaffold.dart';
import '../design_system/theme/app_spacing.dart';
import '../design_system/theme/app_typography.dart';

/// Temporary bootstrap page so the app runs before product screens exist.
///
/// This is NOT a product screen. Remove or replace once the first real
/// feature route (e.g. splash/onboarding/home) is implemented.
class FoundationPlaceholderPage extends StatelessWidget {
  const FoundationPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: AppPagePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppConstants.appName, style: AppTypography.display(context)),
            const AppGap.sm(),
            Text(
              'UI design system is ready. Product screens will be added next '
              'using reusable tokens and components.',
              style: AppTypography.body(context),
            ),
            const AppGap(AppSpacing.xxxl),
            Text('Next step', style: AppTypography.sectionTitle(context)),
            const AppGap.xs(),
            Text(
              'Screenshot/Design → UI analysis → reusable components → '
              'screen implementation.',
              style: AppTypography.bodySmall(context),
            ),
          ],
        ),
      ),
    );
  }
}
