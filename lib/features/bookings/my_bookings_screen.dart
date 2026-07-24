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

/// Route: '/bookings' — Upcoming/Past segmented list via GET /bookings.
///
/// GET /bookings' `status` query param only accepts a single exact status
/// value (not a set), so rather than firing multiple requests this screen
/// fetches page 1 once and splits Upcoming vs. Past client-side by
/// [BookingStatus].
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

enum _Segment { upcoming, past }

const _upcomingStatuses = {BookingStatus.pendingPayment, BookingStatus.confirmed};
const _pastStatuses = {
  BookingStatus.completed,
  BookingStatus.cancelledByConsumer,
  BookingStatus.cancelledByBusiness,
  BookingStatus.noShow,
  BookingStatus.disputed,
  BookingStatus.expired,
};

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _strings = AppStrings.ar;
  _Segment _segment = _Segment.upcoming;
  late Future<List<Booking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchBookings();
  }

  Future<List<Booking>> _fetchBookings() async {
    try {
      final response = await ApiClient.instance.dio.get('/bookings', queryParameters: {'page': 1});
      final data = response.data as Map<String, dynamic>;
      return (data['bookings'] as List? ?? const [])
          .map((b) => Booking.fromJson(b as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // Unwrap so a session expiry always surfaces as SessionExpiredException
      // to the FutureBuilder below, regardless of whether it came straight
      // from Dio or from ApiClient's refresh-retry interceptor.
      if (e.error is SessionExpiredException) throw SessionExpiredException();
      rethrow;
    }
  }

  Future<void> _reload() async {
    final next = _fetchBookings();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // Swallowed here on purpose — the FutureBuilder listening on the same
      // future surfaces the error state; this just lets RefreshIndicator's
      // spinner resolve instead of leaving an unhandled rejection.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_strings.myBookings.title)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Center(
                child: SegmentedButton<_Segment>(
                  segments: [
                    ButtonSegment(value: _Segment.upcoming, label: Text(_strings.myBookings.upcoming)),
                    ButtonSegment(value: _Segment.past, label: Text(_strings.myBookings.past)),
                  ],
                  selected: {_segment},
                  onSelectionChanged: (selection) => setState(() => _segment = selection.first),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Booking>>(
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
                    return _ErrorState(
                      message: isNetwork ? _strings.errors.network : _strings.errors.generic,
                      onRetry: _reload,
                    );
                  }

                  final bookings = snapshot.data ?? const [];
                  final statusSet = _segment == _Segment.upcoming ? _upcomingStatuses : _pastStatuses;
                  final filtered = bookings.where((b) => statusSet.contains(b.status)).toList();

                  if (filtered.isEmpty) {
                    return _EmptyState(strings: _strings, onBrowse: () => context.go('/home'));
                  }

                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = filtered[index];
                        return _BookingCard(
                          booking: booking,
                          onTap: () => context.push('/bookings/${booking.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ar;
    final business = booking.business;
    final accent = business != null ? AppColors.forCategory(business.category.toJson()) : AppColors.navy;
    final slot = booking.slot;
    final dateLabel = slot != null ? DateFormat('EEEE d MMMM، h:mm a', 'ar').format(slot.startTime) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              business?.nameAr ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: booking.status),
                        ],
                      ),
                      if (dateLabel != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dateLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${strings.booking.confirmed.bookingRef}: ${booking.bookingRef}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Center(child: Icon(Icons.chevron_left, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.strings, required this.onBrowse});

  final AppStrings strings;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              strings.myBookings.empty,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 6),
            Text(
              strings.myBookings.emptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onBrowse, child: Text(strings.booking.confirmed.backHome)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ar;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: Text(strings.common.retry)),
          ],
        ),
      ),
    );
  }
}
