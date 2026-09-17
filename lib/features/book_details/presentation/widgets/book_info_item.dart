import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_typography.dart';

class BookInfoItem extends StatelessWidget {
  const BookInfoItem({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.sectionTitle(context)),
        Text(label, style: AppTypography.helper(context)),
      ],
    );
  }
}

class BookInfoRow extends StatelessWidget {
  const BookInfoRow({
    super.key,
    required this.chapters,
    required this.access,
    required this.language,
  });

  final String chapters;
  final String access;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: BookInfoItem(value: chapters, label: 'Chapters')),
        Expanded(child: BookInfoItem(value: access, label: 'Access')),
        Expanded(child: BookInfoItem(value: language, label: 'Language')),
      ],
    );
  }
}
