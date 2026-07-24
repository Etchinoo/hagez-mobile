import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A single tappable category pill for the home screen's horizontal
/// category row, colored via [AppColors.forCategory].
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.categoryKey,
    required this.label,
    required this.onTap,
  });

  /// Raw category string (e.g. 'restaurant', 'gaming_cafe') — matches
  /// [AppColors.forCategory] and the API's category values, NOT the
  /// (possibly translated) [label].
  final String categoryKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forCategory(categoryKey);
    return Material(
      color: accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
