import 'package:flutter/material.dart';

import 'app_button_shared.dart';

/// Text button — uses [TextButton] theme tokens.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.isExpanded = false,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final bool isExpanded;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      height: appButtonHeight(size),
      width: isExpanded ? double.infinity : null,
      child: TextButton(
        onPressed: effectiveOnPressed,
        child: AppButtonChild(
          label: label,
          isLoading: isLoading,
          isExpanded: isExpanded,
          loaderColor: colors.primary,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        ),
      ),
    );
  }
}
