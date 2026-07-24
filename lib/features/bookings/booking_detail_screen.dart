import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/models/booking.dart';
import '../../core/models/business_category.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import 'booking_status_x.dart';

/// Route: '/bookings/:id' — full detail via GET /bookings/:id, with a
/// cancel action (PATCH /bookings/:id/cancel) when the booking is confirmed.
///
/// Reschedule is intentionally NOT built in this pass — the API's
/// PATCH /bookings/:id/reschedule needs a slot-picking UI of its own
/// (reusing the checkout flow's date/time picker) that's real scope beyond
/// this screen. Follow-up, not a stub button.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _strings = AppStrings.ar;
  late Future<Booking> _future;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _future = _fetchBooking();
  }

  Future<Booking> _fetchBooking() async {
    try {
      final response = await ApiClient.instance.dio.get('/bookings/${widget.bookingId}');
      // GET /bookings/:id also returns payments/review/status_logs — ignored
      // here, Booking.fromJson only parses the fields this screen needs.
      return Booking.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.error is SessionExpiredException) throw SessionExpiredException();
      rethrow;
    }
  }

  Future<void> _handleCancelTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_strings.myBookings.cancel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_strings.myBookings.cancelConfirm),
            const SizedBox(height: 12),
            Text(
              '•  ${_strings.myBookings.cancelInsideWindow}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              '•  ${_strings.myBookings.cancelOutsideWindow}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_strings.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(_strings.common.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) await _cancelBooking();
  }

  Future<void> _cancelBooking() async {
    setState(() => _cancelling = true);
    try {
      await ApiClient.instance.dio.patch('/bookings/${widget.bookingId}/cancel', data: {});
      final updated = await _fetchBooking();
      if (!mounted) return;
      setState(() {
        _future = Future.value(updated);
        _cancelling = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      if (e.error is SessionExpiredException) {
        context.go('/login');
        return;
      }
      final isNetwork = e.response == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetwork ? _strings.errors.network : _strings.errors.generic)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_strings.errors.generic)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_strings.myBookings.title)),
      body: FutureBuilder<Booking>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            if (error is SessionExpiredException) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go('/login');
              });
              return const SizedBox.shrink();
            }
            final isNetwork = error is DioException && error.response == null;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      isNetwork ? _strings.errors.network : _strings.errors.generic,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => _future = _fetchBooking()),
                      child: Text(_strings.common.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final booking = snapshot.data!;
          return _BookingDetailBody(
            booking: booking,
            cancelling: _cancelling,
            onCancel: _handleCancelTap,
          );
        },
      ),
    );
  }
}

class _BookingDetailBody extends StatelessWidget {
  const _BookingDetailBody({required this.booking, required this.cancelling, required this.onCancel});

  final Booking booking;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ar;
    final business = booking.business;
    final slot = booking.slot;
    final accent = business != null ? AppColors.forCategory(business.category.toJson()) : AppColors.navy;

    final dateLabel = slot != null ? DateFormat('EEEE d MMMM y', 'ar').format(slot.startTime) : null;
    final timeLabel = slot != null
        ? '${DateFormat('h:mm a', 'ar').format(slot.startTime)} – ${DateFormat('h:mm a', 'ar').format(slot.endTime)}'
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        business?.nameAr ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: booking.status),
                  ],
                ),
                if (business != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(business.district, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dateLabel != null) _DetailRow(icon: Icons.calendar_today_outlined, text: dateLabel),
                if (timeLabel != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.access_time, text: timeLabel),
                ],
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.people_outline,
                  text: '${strings.booking.partySize}: ${booking.partySize}',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.confirmation_number_outlined,
                  text: '${strings.booking.confirmed.bookingRef}: ${booking.bookingRef}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.booking.summary.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
                const SizedBox(height: 12),
                _MoneyRow(label: strings.booking.summary.deposit, amount: booking.depositAmount, egp: strings.common.egp),
                const SizedBox(height: 8),
                _MoneyRow(
                  label: strings.booking.summary.platformFee,
                  amount: booking.platformFee,
                  egp: strings.common.egp,
                ),
                const Divider(height: 24),
                _MoneyRow(
                  label: strings.booking.summary.total,
                  amount: booking.totalAmount,
                  egp: strings.common.egp,
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        if (booking.status == BookingStatus.confirmed) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: cancelling ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: cancelling
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                    )
                  : Text(strings.myBookings.cancel),
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.navy))),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.amount, required this.egp, this.bold = false});

  final String label;
  final double amount;
  final String egp;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: AppColors.navy,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('${amount.round()} $egp', style: style),
      ],
    );
  }
}
