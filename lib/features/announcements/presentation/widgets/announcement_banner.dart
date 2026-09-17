import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/open_url.dart';
import '../../../../data/models/announcement.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';

class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key, required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceMutedDark,
          borderRadius: AppRadii.cardBorder,
        ),
        child: Padding(
          padding: AppInsets.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (announcement.imageUrl != null &&
                  announcement.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: AppRadii.cardBorder,
                  child: CachedNetworkImage(
                    imageUrl: announcement.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (announcement.imageUrl != null) const AppGap.md(),
              Text(announcement.title, style: AppTypography.sectionTitle(context)),
              const AppGap.xs(),
              Text(announcement.message, style: AppTypography.helper(context)),
              if (announcement.hasAction)
                Align(
                  alignment: Alignment.centerRight,
                  child: AppTextButton(
                    label: announcement.actionLabel!,
                    compact: true,
                    onPressed: () => openSafeHttpUrl(announcement.actionUrl),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
