import 'package:flutter/material.dart';

import '../../design_system/components/buttons/app_button.dart';
import '../../design_system/components/feedback/app_empty_state.dart';
import '../../design_system/components/feedback/app_loader.dart';
import '../../design_system/icons/app_icons.dart';

class AsyncBody extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.loading,
    required this.errorMessage,
    required this.isEmpty,
    required this.onRetry,
    required this.child,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage,
    this.loadingPlaceholder,
  });

  final bool loading;
  final String? errorMessage;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget child;
  final String emptyTitle;
  final String? emptyMessage;
  final Widget? loadingPlaceholder;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return loadingPlaceholder ?? const AppLoaderPage();
    }
    if (errorMessage != null) {
      return AppEmptyState(
        icon: AppIcons.error,
        title: 'Could not load',
        message: errorMessage,
        action: AppButton(
          label: 'Retry',
          isExpanded: false,
          onPressed: onRetry,
        ),
      );
    }
    if (isEmpty) {
      return AppEmptyState(
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return child;
  }
}
