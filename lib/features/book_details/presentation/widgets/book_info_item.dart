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
    required this.pages,
    required this.readTime,
    required this.language,
  });

  final String pages;
  final String readTime;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: BookInfoItem(value: pages, label: 'Pages')),
        Expanded(child: BookInfoItem(value: readTime, label: 'Read time')),
        Expanded(child: BookInfoItem(value: language, label: 'Language')),
      ],
    );
  }
}
