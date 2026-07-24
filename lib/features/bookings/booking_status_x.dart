import 'package:flutter/material.dart';

import '../../core/models/business_category.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';

/// [BookingStatus] doesn't expose its raw API string (only [BookingStatus.fromJson]
/// parses one), but AppStrings.myBookings.statuses and colour choices both key
/// off that snake_case string — so this mirrors the reverse mapping in one
/// place shared by MyBookingsScreen and BookingDetailScreen.
extension BookingStatusDisplay on BookingStatus {
  String get apiKey => switch (this) {
        BookingStatus.pendingPayment => 'pending_payment',
        BookingStatus.confirmed => 'confirmed',
        BookingStatus.completed => 'completed',
        BookingStatus.cancelledByConsumer => 'cancelled_by_consumer',
        BookingStatus.cancelledByBusiness => 'cancelled_by_business',
        BookingStatus.noShow => 'no_show',
        BookingStatus.disputed => 'disputed',
        BookingStatus.expired => 'expired',
      };

  Color get badgeColor => switch (this) {
        BookingStatus.confirmed => AppColors.teal,
        BookingStatus.pendingPayment => AppColors.warning,
        BookingStatus.completed => AppColors.navy,
        BookingStatus.cancelledByConsumer => AppColors.textSecondary,
        BookingStatus.cancelledByBusiness => AppColors.textSecondary,
        BookingStatus.noShow => AppColors.error,
        BookingStatus.disputed => AppColors.warning,
        BookingStatus.expired => AppColors.textSecondary,
      };
}

/// Small coloured pill for a booking's status, labelled from
/// AppStrings.ar.myBookings.statuses.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final label = AppStrings.ar.myBookings.statuses[status.apiKey] ?? status.apiKey;
    final color = status.badgeColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
