import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// Search field used on Home (read-only entry) and Search (editable).
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search titles, authors, genres',
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.searchBarHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        readOnly: readOnly,
        autofocus: autofocus,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(AppIcons.search, size: AppSizes.iconMd),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadii.searchBarBorder,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
