import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';
import '../../theme/app_radii.dart';
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
    this.backgroundColor,
    this.foregroundColor,
    this.gradient = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final bool isExpanded;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;
    final Color loaderColor = foregroundColor ?? colors.onPrimary;

    ButtonStyle? overrideStyle;
    if (gradient) {
      overrideStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: foregroundColor ?? colors.onPrimary,
      );
    } else if (backgroundColor != null || foregroundColor != null) {
      overrideStyle = ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      );
    }

    final Widget button = SizedBox(
      height: appButtonHeight(size),
      width: isExpanded ? double.infinity : null,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: overrideStyle,
        child: AppButtonChild(
          label: label,
          isLoading: isLoading,
          isExpanded: isExpanded,
          loaderColor: loaderColor,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
        ),
      ),
    );

    if (!gradient) return button;

    return ClipRRect(
      borderRadius: AppRadii.buttonBorder,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.brand),
        child: button,
      ),
    );
  }
}
