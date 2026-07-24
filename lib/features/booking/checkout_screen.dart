import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/models/slot.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';

/// Route: '/checkout/:businessId' — universal booking-creation flow:
/// date/time slot selection, party size stepper, optional special requests
/// → POST /bookings (creates the slot hold) → '/payment/:bookingId'.
///
/// Category-specific fields (occasion, staff, station/genre, vehicle type)
/// are intentionally NOT built in this pass — see the follow-up note at the
/// bottom of this file for exactly what's missing per category.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.businessId});
  final String businessId;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _minPartySize = 1;
  static const _maxPartySize = 12;
  static const _dateOptionCount = 14;

  late final List<DateTime> _dateOptions;
  late DateTime _selectedDate;

  bool _slotsLoading = true;
  String? _slotsError;
  List<Slot> _slots = const [];
  Slot? _selectedSlot;

  int _partySize = _minPartySize;
  final _specialRequestsController = TextEditingController();

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dateOptions = List.generate(_dateOptionCount, (i) => today.add(Duration(days: i)));
    _selectedDate = today;
    _fetchSlots();
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _slotsLoading = true;
      _slotsError = null;
      _selectedSlot = null;
    });

    try {
      final dateParam = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await ApiClient.instance.dio.get(
        '/businesses/${widget.businessId}/slots',
        queryParameters: {'date': dateParam},
      );
      final raw = response.data;
      final list = raw is List ? raw : (raw as Map<String, dynamic>?)?['slots'] as List? ?? const [];
      final slots = list.map((s) => Slot.fromJson(s as Map<String, dynamic>)).toList();

      if (!mounted) return;
      setState(() {
        _slots = slots;
        _slotsLoading = false;
      });
    } on SessionExpiredException {
      if (!mounted) return;
      context.go('/login');
    } on DioException {
      if (!mounted) return;
      setState(() {
        _slotsLoading = false;
        _slotsError = AppStrings.ar.errors.network;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slotsLoading = false;
        _slotsError = AppStrings.ar.errors.generic;
      });
    }
  }

  void _onDateSelected(DateTime date) {
    if (_isSameDay(date, _selectedDate)) return;
    setState(() => _selectedDate = date);
    _fetchSlots();
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _incrementPartySize() {
    if (_partySize >= _maxPartySize) return;
    setState(() => _partySize++);
  }

  void _decrementPartySize() {
    if (_partySize <= _minPartySize) return;
    setState(() => _partySize--);
  }

  Future<void> _confirm() async {
    final slot = _selectedSlot;
    if (slot == null || _submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final specialRequests = _specialRequestsController.text.trim();
      final response = await ApiClient.instance.dio.post('/bookings', data: {
        'slot_id': slot.id,
        'business_id': widget.businessId,
        'party_size': _partySize,
        if (specialRequests.isNotEmpty) 'special_requests': specialRequests,
      });

      final data = response.data as Map<String, dynamic>;
      final bookingId = data['booking_id'] as String;

      if (!mounted) return;
      context.push('/payment/$bookingId');
    } on SessionExpiredException {
      if (!mounted) return;
      context.go('/login');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = _errorMessageFor(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = AppStrings.ar.errors.generic;
      });
    }
  }

  /// On a 409 conflict, prefer the server's Arabic message; fall back to a
  /// known-code mapping, then to the generic error string.
  String _errorMessageFor(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final errorField = data['error'];
      final messageAr = (data['message_ar'] as String?) ??
          (errorField is Map ? errorField['message_ar'] as String? : null);
      if (messageAr != null && messageAr.trim().isNotEmpty) return messageAr;

      if (e.response?.statusCode == 409) {
        final code = (data['code'] as String?) ??
            (errorField is Map ? errorField['code'] as String? : (errorField is String ? errorField : null));
        if (code == 'SLOT_ALREADY_HELD') return AppStrings.ar.errors.slotTaken;
        if (code == 'SLOT_CAPACITY_EXCEEDED') return AppStrings.ar.errors.capacityExceeded;
      }
    }
    return AppStrings.ar.errors.generic;
  }

  String _formatEgp(double amount) => '${amount.round()} ${AppStrings.ar.common.egp}';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ar;

    return Scaffold(
      appBar: AppBar(title: Text(strings.booking.checkoutTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(strings.booking.selectDate),
                    const SizedBox(height: 10),
                    _DateSelector(
                      dates: _dateOptions,
                      selectedDate: _selectedDate,
                      onSelected: _onDateSelected,
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(strings.booking.selectTime),
                    const SizedBox(height: 10),
                    _buildSlotsArea(strings),
                    const SizedBox(height: 24),
                    _SectionLabel(strings.booking.partySize),
                    const SizedBox(height: 10),
                    _PartySizeStepper(
                      value: _partySize,
                      min: _minPartySize,
                      max: _maxPartySize,
                      onIncrement: _incrementPartySize,
                      onDecrement: _decrementPartySize,
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(strings.booking.specialRequests),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _specialRequestsController,
                      maxLines: 3,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
                      decoration: InputDecoration(hintText: strings.booking.specialRequestsPlaceholder),
                    ),
                    if (_selectedSlot != null) ...[
                      const SizedBox(height: 24),
                      _BookingSummaryCard(
                        depositAmount: _selectedSlot!.depositAmount,
                        formatEgp: _formatEgp,
                      ),
                    ],
                    if (_submitError != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _submitError!),
                    ],
                  ],
                ),
              ),
            ),
            _buildConfirmBar(strings),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsArea(AppStrings strings) {
    if (_slotsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_slotsError != null) {
      return _ErrorBanner(
        message: _slotsError!,
        onRetry: _fetchSlots,
        retryLabel: strings.common.retry,
      );
    }

    if (_slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          strings.booking.noSlotsAvailable,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: AppColors.textSecondary),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _slots.map((slot) {
        final isSelected = _selectedSlot?.id == slot.id;
        final isFull = slot.availableCapacity <= 0;
        return _SlotChip(
          slot: slot,
          selected: isSelected,
          disabled: isFull,
          onTap: isFull ? null : () => setState(() => _selectedSlot = slot),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmBar(AppStrings strings) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: ElevatedButton(
          onPressed: _selectedSlot != null && !_submitting ? _confirm : null,
          child: _submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                )
              : Text(strings.booking.confirmCta),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.dates, required this.selectedDate, required this.onSelected});

  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, selectedDate);
          final weekday = DateFormat('EEE', 'ar').format(date);
          final dayMonth = DateFormat('d MMM', 'ar').format(date);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(date),
            child: Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.teal : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.teal : AppColors.border, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekday,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayMonth,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot, required this.selected, required this.disabled, required this.onTap});

  final Slot slot;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('h:mm a', 'ar').format(slot.startTime);

    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}

class _PartySizeStepper extends StatelessWidget {
  const _PartySizeStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int value;
  final int min;
  final int max;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepperButton(icon: Icons.remove, onPressed: value > min ? onDecrement : null),
          Text(
            '$value',
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
          _StepperButton(icon: Icons.add, onPressed: value < max ? onIncrement : null),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.teal.withValues(alpha: 0.1) : AppColors.background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: enabled ? AppColors.teal : AppColors.textSecondary),
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({required this.depositAmount, required this.formatEgp});

  final double depositAmount;
  final String Function(double) formatEgp;

  static const _placeholder = '—';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ar.booking.summary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.title,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: strings.deposit, value: formatEgp(depositAmount)),
          const SizedBox(height: 8),
          _SummaryRow(label: strings.platformFee, value: _placeholder),
          const SizedBox(height: 8),
          _SummaryRow(label: strings.total, value: _placeholder, emphasize: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            color: emphasize ? AppColors.navy : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: emphasize ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.onRetry, this.retryLabel});
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.error),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? AppStrings.ar.common.retry),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// FOLLOW-UP — category-specific fields NOT built in this pass.
// This screen only implements the universal fields (date/time, party_size,
// special_requests). Whoever picks this up next needs to add, per category
// (branch on BusinessCategory, likely fetched via GET /businesses/:id or
// passed as extra into this route):
//
//   - restaurant:   an `occasion` enum picker (e.g. birthday/anniversary/
//                    business/casual — confirm exact enum values with the
//                    API) shown after party size, sent as `occasion` in the
//                    POST /bookings body.
//   - salon:        a `resource_id` staff picker — list of BusinessResource
//                    (from Business.resources, "staff" key) with an "any
//                    staff" option (see AppStrings.ar.business.anyStaff),
//                    sent as `resource_id`.
//   - gaming_cafe:  a `station_type` picker (from the business's
//                    gaming_config / stations resources) AND a separate
//                    `genre_preference` field (likely a short picklist —
//                    confirm allowed values with the API), both sent
//                    alongside the booking body.
//   - car_wash:     a `vehicle_size` picker (small/medium/large/SUV — confirm
//                    exact enum with the API), sent as `vehicle_size`.
//   - court:        resource_id court/pitch picker, similar shape to salon's
//                    staff picker (not explicitly called out in the task but
//                    likely needed given `court_config` exists on Business).
//
// These fields should probably render conditionally between the party-size
// stepper and the special-requests field, driven by widget.businessId's
// category (this screen doesn't currently fetch the Business itself — that
// would need to happen first, or the category could be passed as `extra`
// from BusinessDetailScreen to avoid a second fetch).
//
// Also NOT done in this pass (small scope cuts, flagged for honesty):
//   - Party size is not capped by the selected slot's `availableCapacity`;
//     the server still enforces this via a 409 SLOT_CAPACITY_EXCEEDED,
//     which this screen does handle, but there's no client-side pre-check.
//   - platform_fee / total in the summary card are shown as "—" until the
//     POST succeeds (per the task's explicit instruction) — since a
//     successful POST immediately navigates to the payment screen, those
//     two placeholders are never actually filled in on this screen; the
//     payment screen is presumably where the real total/fee should surface.
//   - No 8-minute hold countdown UI here (slot_hold_expires_at is returned
//     by POST /bookings but only consumed on the payment screen).
// ============================================================
