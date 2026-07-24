import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/models/booking.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';

/// Route: '/confirmed/:bookingId' — success state, booking summary,
/// "view booking" / "home" CTAs. Fetches GET /bookings/:id for the real
/// booking_ref + business/slot/party-size summary.
class ConfirmedScreen extends StatefulWidget {
  const ConfirmedScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<ConfirmedScreen> createState() => _ConfirmedScreenState();
}

class _ConfirmedScreenState extends State<ConfirmedScreen> {
  final _strings = AppStrings.ar;
  late Future<Booking> _bookingFuture;

  @override
  void initState() {
    super.initState();
    _bookingFuture = _fetchBooking();
  }

  Future<Booking> _fetchBooking() async {
    final response = await ApiClient.instance.dio.get('/bookings/${widget.bookingId}');
    return Booking.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    final s = _strings.booking.confirmed;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppColors.teal, size: 64),
              ),
              const SizedBox(height: 24),
              Text(
                s.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 8),
              Text(
                s.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: FutureBuilder<Booking>(
                  future: _bookingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      if (snapshot.error is DioException &&
                          (snapshot.error as DioException).error is SessionExpiredException) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) context.go('/login');
                        });
                        return const SizedBox.shrink();
                      }
                      return _ErrorSummary(
                        message: _strings.errors.generic,
                        onRetry: () => setState(() => _bookingFuture = _fetchBooking()),
                        retryLabel: _strings.common.retry,
                      );
                    }
                    final booking = snapshot.data!;
                    return _BookingSummaryCard(booking: booking, bookingRefLabel: s.bookingRef);
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go('/bookings'),
                child: Text(s.viewBookings),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  foregroundColor: AppColors.navy,
                ),
                onPressed: () => context.go('/home'),
                child: Text(s.backHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({required this.booking, required this.bookingRefLabel});
  final Booking booking;
  final String bookingRefLabel;

  @override
  Widget build(BuildContext context) {
    final business = booking.business;
    final slot = booking.slot;
    final dateFormat = DateFormat('EEEE، d MMMM', 'ar');
    final timeFormat = DateFormat('h:mm a', 'ar');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bookingRefLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                Text(
                  booking.bookingRef,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            if (business != null) ...[
              const Divider(height: 28),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.forCategory(business.category.toJson()),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      business.nameAr,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(business.district, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
            if (slot != null) ...[
              const SizedBox(height: 16),
              _SummaryRow(icon: Icons.calendar_today, text: dateFormat.format(slot.startTime)),
              const SizedBox(height: 8),
              _SummaryRow(
                icon: Icons.access_time,
                text: '${timeFormat.format(slot.startTime)} - ${timeFormat.format(slot.endTime)}',
              ),
            ],
            const SizedBox(height: 8),
            _SummaryRow(icon: Icons.people_outline, text: '${booking.partySize}'),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 14, color: AppColors.navy)),
      ],
    );
  }
}

class _ErrorSummary extends StatelessWidget {
  const _ErrorSummary({required this.message, required this.onRetry, required this.retryLabel});
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
