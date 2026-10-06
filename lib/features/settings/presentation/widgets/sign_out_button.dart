import 'package:flutter/material.dart';

import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';

/// Gold-outlined sign-out action shared by Profile and Settings.
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadii.full);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.brandPrimary.withOpacity(0.55)),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: AppSizes.buttonHeightMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                AppIcons.signOut,
                size: AppSizes.iconMd,
                color: AppColors.brandAccent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Sign out',
                style: AppTypography.label(context).copyWith(
                  color: AppColors.brandAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
