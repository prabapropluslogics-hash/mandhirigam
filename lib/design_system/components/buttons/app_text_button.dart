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
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final bool isExpanded;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    final Widget button = TextButton(
      onPressed: effectiveOnPressed,
      child: AppButtonChild(
        label: label,
        isLoading: isLoading,
        isExpanded: isExpanded,
        loaderColor: colors.primary,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
      ),
    );

    if (compact) {
      return button;
    }

    return SizedBox(
      height: appButtonHeight(size),
      width: isExpanded ? double.infinity : null,
      child: button,
    );
  }
}
