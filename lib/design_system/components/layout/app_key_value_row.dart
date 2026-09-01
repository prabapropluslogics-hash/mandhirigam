import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

/// Label on the left, value on the right — used in order summaries and similar.
class AppKeyValueRow extends StatelessWidget {
  const AppKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final TextStyle defaultLabel =
        labelStyle ?? AppTypography.helper(context);
    final TextStyle defaultValue =
        valueStyle ?? AppTypography.body(context);

    return Row(
      children: [
        Expanded(child: Text(label, style: defaultLabel)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: defaultValue,
          ),
        ),
      ],
    );
  }
}
