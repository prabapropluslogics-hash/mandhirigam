import 'package:flutter/material.dart';

import 'app_button_shared.dart';

/// Primary (filled) button — uses [ElevatedButton] theme tokens.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.isExpanded = true,
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
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        child: AppButtonChild(
          label: label,
          isLoading: isLoading,
          isExpanded: isExpanded,
          loaderColor: colors.onPrimary,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        ),
      ),
    );
  }
}
