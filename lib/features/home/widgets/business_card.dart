import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/business.dart';
import '../../../core/models/business_category.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_strings.dart';

/// Reusable card for a [Business] in a horizontally-scrollable discovery
/// row (home screen "featured"/"nearby" sections). Tapping navigates to
/// '/business/:id'.
///
/// Kept in lib/features/home/widgets per the project convention of scoping
/// small shared widgets to the feature folder that introduced them — reuse
/// from lib/features/search is fine via a relative import if needed later.
class BusinessCard extends StatelessWidget {
  const BusinessCard({super.key, required this.business});

  final Business business;

  static const double width = 168;
  static const double _imageHeight = 110;

  static IconData _iconForCategory(BusinessCategory category) => switch (category) {
        BusinessCategory.restaurant => Icons.restaurant,
        BusinessCategory.salon => Icons.content_cut,
        BusinessCategory.court => Icons.sports_tennis,
        BusinessCategory.gamingCafe => Icons.sports_esports,
        BusinessCategory.carWash => Icons.local_car_wash,
        BusinessCategory.medical => Icons.local_hospital,
      };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ar;
    final accent = AppColors.forCategory(business.category.toJson());
    final categoryLabel = strings.home.categories[business.category.toJson()] ?? '';

    return GestureDetector(
      onTap: () => context.push('/business/${business.id}'),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: _imageHeight,
                  width: double.infinity,
                  child: business.photos.isEmpty
                      ? _CategoryPlaceholder(accent: accent, icon: _iconForCategory(business.category))
                      : CachedNetworkImage(
                          imageUrl: business.photos.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.background),
                          errorWidget: (context, url, error) =>
                              _CategoryPlaceholder(accent: accent, icon: _iconForCategory(business.category)),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      categoryLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    business.nameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          business.district,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (business.ratingAvg != null)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          business.ratingAvg!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${business.reviewCount})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        strings.business.newBadge,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback shown in place of the first photo when [Business.photos] is
/// empty — a category-accented tint with a representative icon, so the
/// card never crashes or shows a broken-image glyph.
class _CategoryPlaceholder extends StatelessWidget {
  const _CategoryPlaceholder({required this.accent, required this.icon});

  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(icon, color: accent, size: 32),
    );
  }
}
