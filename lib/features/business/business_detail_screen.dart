import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/models/business.dart';
import '../../core/models/business_category.dart';
import '../../core/models/slot.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';

enum _LoadState { loading, loaded, notFound, error }

/// Route: '/business/:id' — hero photos, description, category-specific
/// resources (staff/courts/stations), next available slots, book CTA.
///
/// Fetches GET /businesses/:id on load. A plain StatefulWidget + local state
/// is used here (single fetch-once screen) rather than a Riverpod provider,
/// consistent with the "use your judgement" guidance for screen-level data.
class BusinessDetailScreen extends StatefulWidget {
  const BusinessDetailScreen({super.key, required this.businessId});
  final String businessId;

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  _LoadState _state = _LoadState.loading;
  Business? _business;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = _LoadState.loading;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.instance.dio.get('/businesses/${widget.businessId}');
      final business = Business.fromDetailJson(response.data as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _business = business;
        _state = _LoadState.loaded;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      // ApiClient's 401 interceptor rejects with a DioException wrapping a
      // SessionExpiredException once a refresh attempt is exhausted.
      if (e.error is SessionExpiredException) {
        context.go('/login');
        return;
      }
      if (e.response?.statusCode == 404) {
        setState(() => _state = _LoadState.notFound);
        return;
      }
      final s = AppStrings.ar.errors;
      final isNetworkError = e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      setState(() {
        _errorMessage = isNetworkError ? s.network : s.generic;
        _state = _LoadState.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppStrings.ar.errors.generic;
        _state = _LoadState.error;
      });
    }
  }

  void _goToCheckout() {
    // NOTE: checkout is intentionally opened without a preselected slot.
    // '/checkout/:businessId' (see lib/core/router/app_router.dart) doesn't
    // currently accept `extra` data, and CheckoutScreen only takes a
    // businessId — wiring a preselected slot through would mean touching
    // both files, which are owned by the concurrently-running booking-flow
    // agent. Follow-up: once checkout supports it, pass the tapped slot id.
    context.push('/checkout/${widget.businessId}');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.ar;
    return Scaffold(
      appBar: AppBar(
        title: Text(_business?.nameAr ?? s.common.appName),
      ),
      body: switch (_state) {
        _LoadState.loading => const Center(child: CircularProgressIndicator()),
        _LoadState.notFound => _NotFoundView(strings: s),
        _LoadState.error => _ErrorView(message: _errorMessage ?? s.errors.generic, onRetry: _load),
        _LoadState.loaded => _BusinessDetailBody(business: _business!),
      },
      bottomNavigationBar: _state == _LoadState.loaded
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ElevatedButton(
                onPressed: _goToCheckout,
                child: Text(s.business.bookNow),
              ),
            )
          : null,
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              strings.business.notFound,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.ar.common;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: Text(s.retry)),
          ],
        ),
      ),
    );
  }
}

class _BusinessDetailBody extends StatelessWidget {
  const _BusinessDetailBody({required this.business});
  final Business business;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.ar;
    final categoryColor = AppColors.forCategory(business.category.toJson());
    final categoryLabel = s.home.categories[business.category.toJson()] ?? business.category.toJson();
    final resourcesLabel = _resourcesLabel(business.category, s);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Hero(photos: business.photos),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                business.nameAr,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _CategoryBadge(color: categoryColor, label: categoryLabel),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text(business.district, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                  _RatingOrNewBadge(business: business, strings: s),
                ],
              ),
              if ((business.descriptionAr ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  s.business.about,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  business.descriptionAr!,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ],
          ),
        ),
        if (resourcesLabel != null && (business.resources ?? const []).isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              resourcesLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: business.resources!.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final resource = business.resources![index];
                final typeBadge = business.category == BusinessCategory.gamingCafe &&
                        resource.specialisations.isNotEmpty
                    ? resource.specialisations.first
                    : null;
                return _ResourceCard(nameAr: resource.nameAr, typeBadge: typeBadge, color: categoryColor);
              },
            ),
          ),
        ],
        if ((business.nextAvailableSlots ?? const []).isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              s.business.nextAvailableSlots,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: business.nextAvailableSlots!.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final slot = business.nextAvailableSlots![index];
                return _SlotChip(
                  slot: slot,
                  color: categoryColor,
                  onTap: () => context.push('/checkout/${business.id}'),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Resources are only populated by the API for salon/court/gaming_cafe —
  /// restaurant and car_wash have no `resources` section to render.
  static String? _resourcesLabel(BusinessCategory category, AppStrings s) => switch (category) {
        BusinessCategory.salon => s.business.staff,
        BusinessCategory.court => s.business.courts,
        BusinessCategory.gamingCafe => s.business.stations,
        _ => null,
      };
}

class _Hero extends StatefulWidget {
  const _Hero({required this.photos});
  final List<String> photos;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const height = 240.0;

    if (widget.photos.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: AppColors.border,
        child: const Icon(Icons.storefront_outlined, size: 56, color: AppColors.textSecondary),
      );
    }

    if (widget.photos.length == 1) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: widget.photos.first,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(color: AppColors.border),
          errorWidget: (_, _, _) => Container(
            color: AppColors.border,
            child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: widget.photos[index],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, _) => Container(color: AppColors.border),
              errorWidget: (_, _, _) => Container(
                color: AppColors.border,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.photos.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _page ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _RatingOrNewBadge extends StatelessWidget {
  const _RatingOrNewBadge({required this.business, required this.strings});
  final Business business;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (business.isNew || business.ratingAvg == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          strings.business.newBadge,
          style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
        const SizedBox(width: 2),
        Text(
          '${business.ratingAvg!.toStringAsFixed(1)} (${strings.business.reviewsCount(business.reviewCount)})',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.nameAr, required this.color, this.typeBadge});
  final String nameAr;
  final String? typeBadge;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (typeBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(
                typeBadge!,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            nameAr,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot, required this.color, required this.onTap});
  final Slot slot;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPricingNote = slot.effectiveDeposit != slot.depositAmount && (slot.pricingBadgeAr ?? '').isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat.Hm('ar').format(slot.startTime),
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            if (hasPricingNote)
              Text(
                slot.pricingBadgeAr!,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
