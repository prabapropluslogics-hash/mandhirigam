import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    this.onFreeSample,
    this.onUnlockPremium,
  }) : onStartReading = null;

  const BottomActionBar.startReading({
    super.key,
    required this.onStartReading,
  })  : onFreeSample = null,
        onUnlockPremium = null;

  final VoidCallback? onFreeSample;
  final VoidCallback? onUnlockPremium;
  final VoidCallback? onStartReading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundFor(Theme.of(context).brightness),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppInsets.page,
          child: onStartReading != null
              ? AppButton(
                  label: 'Start reading',
                  size: AppButtonSize.large,
                  leadingIcon: AppIcons.play,
                  backgroundColor: AppColors.neutral50,
                  foregroundColor: AppColors.textOnBrand,
                  onPressed: onStartReading,
                )
              : Row(
                  children: [
                    Expanded(
                      child: AppOutlinedButton(
                        label: 'Free sample',
                        size: AppButtonSize.large,
                        isExpanded: true,
                        onPressed: onFreeSample,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Unlock premium',
                        size: AppButtonSize.large,
                        leadingIcon: AppIcons.lock,
                        onPressed: onUnlockPremium,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
