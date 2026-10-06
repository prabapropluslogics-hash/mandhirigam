import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import 'google_mark.dart';

/// Warm-cream "Continue with Google" button with the Google mark and a soft
/// lift — the single sign-in call to action used across the app.
class GoogleContinueButton extends StatelessWidget {
  const GoogleContinueButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Google',
    this.isLoading = false,
    this.isExpanded = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.buttonBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWithOpacity(0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.brandPrimary.withOpacity(0.16),
            blurRadius: 28,
            spreadRadius: -6,
          ),
        ],
      ),
      child: AppButton(
        label: label,
        size: AppButtonSize.large,
        isExpanded: isExpanded,
        isLoading: isLoading,
        onPressed: onPressed,
        leading: const GoogleMark(size: AppSizes.iconMd),
        backgroundColor: AppColors.neutral50,
        foregroundColor: AppColors.textOnBrand,
      ),
    );
  }
}
