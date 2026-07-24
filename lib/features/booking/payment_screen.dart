import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';

/// Route: '/payment/:bookingId' — payment method selection, 8-min hold
/// countdown, hands off to Paymob → POST /bookings/:id/pay.
///
/// NOTE on the countdown: this screen's constructor only receives [bookingId]
/// (no exact hold-expiry timestamp is threaded through the router today).
/// Rather than touch the shared app_router.dart / checkout flow while other
/// agents may be mid-edit there, the countdown is a local approximation:
/// 8:00 starting from when this screen mounts. In practice the real hold is
/// anchored to when the booking was created on checkout (a few seconds
/// earlier), so this can slightly over-count. Follow-up: thread the real
/// `slot_hold_expires_at` (already returned by POST /bookings) through as a
/// `DateTime?` `extra` on the '/payment/:bookingId' route for a precise
/// countdown.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _PaymentMethod { card, instapay, fawry, vodafone, meeza }

extension on _PaymentMethod {
  /// Matches the API's `PaymentMethod` enum (packages/api prisma schema).
  String get apiValue => switch (this) {
        _PaymentMethod.card => 'card',
        _PaymentMethod.instapay => 'instapay',
        _PaymentMethod.fawry => 'fawry',
        _PaymentMethod.vodafone => 'vodafone_cash',
        _PaymentMethod.meeza => 'meeza',
      };

  IconData get icon => switch (this) {
        _PaymentMethod.card => Icons.credit_card,
        _PaymentMethod.instapay => Icons.account_balance,
        _PaymentMethod.fawry => Icons.storefront,
        _PaymentMethod.vodafone => Icons.phone_android,
        _PaymentMethod.meeza => Icons.credit_score,
      };

  String label(BookingPaymentStrings s) => switch (this) {
        _PaymentMethod.card => s.card,
        _PaymentMethod.instapay => s.instapay,
        _PaymentMethod.fawry => s.fawry,
        _PaymentMethod.vodafone => s.vodafone,
        _PaymentMethod.meeza => s.meeza,
      };
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _holdSeconds = 8 * 60;

  final _strings = AppStrings.ar;
  _PaymentMethod? _selected;
  Timer? _timer;
  int _remainingSeconds = _holdSeconds;
  bool _isPaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isExpired => _remainingSeconds <= 0;

  String get _formattedCountdown {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _pay() async {
    if (_selected == null || _isExpired || _isPaying) return;

    setState(() {
      _isPaying = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.instance.dio.post(
        '/bookings/${widget.bookingId}/pay',
        data: {'payment_method': _selected!.apiValue},
      );

      final iframeUrl = response.data['iframe_url'] as String?;
      // ── STUB: real Paymob WebView integration is separate follow-up work ──
      // The API returns a genuine Paymob `iframe_url` that would normally be
      // opened in an in-app WebView so the user completes card/wallet entry
      // on Paymob's hosted page, with the webhook (POST /webhooks/paymob)
      // confirming payment server-side before the booking is truly
      // `confirmed`. Building that WebView flow needs real Paymob sandbox
      // credentials to test against, which this pass doesn't have. For now,
      // receiving a non-null `iframe_url` is treated as payment success and
      // we navigate straight to the confirmation screen. This is a
      // deliberate scope cut — do not mistake this for a real payment
      // capture.
      if (iframeUrl != null && mounted) {
        context.go('/confirmed/${widget.bookingId}');
      } else if (mounted) {
        setState(() {
          _isPaying = false;
          _errorMessage = _strings.errors.generic;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.error is SessionExpiredException) {
        context.go('/login');
        return;
      }
      setState(() {
        _isPaying = false;
        _errorMessage = e.response != null ? _strings.errors.generic : _strings.errors.network;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPaying = false;
        _errorMessage = _strings.errors.generic;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _strings.booking.payment;

    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: Column(
        children: [
          _HoldBanner(
            expired: _isExpired,
            formattedCountdown: _formattedCountdown,
            heldLabel: _strings.booking.slotHeld,
            minutesLabel: _strings.booking.minutes,
            expiredLabel: _strings.booking.slotExpired,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final method in _PaymentMethod.values)
                  _PaymentMethodTile(
                    icon: method.icon,
                    label: method.label(s),
                    selected: _selected == method,
                    enabled: !_isExpired && !_isPaying,
                    onTap: () => setState(() => _selected = method),
                  ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton(
                onPressed: (_selected != null && !_isExpired && !_isPaying) ? _pay : null,
                child: _isPaying
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(s.payNow),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldBanner extends StatelessWidget {
  const _HoldBanner({
    required this.expired,
    required this.formattedCountdown,
    required this.heldLabel,
    required this.minutesLabel,
    required this.expiredLabel,
  });

  final bool expired;
  final String formattedCountdown;
  final String heldLabel;
  final String minutesLabel;
  final String expiredLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: expired ? AppColors.error.withValues(alpha: 0.1) : AppColors.successBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            expired ? Icons.timer_off : Icons.timer_outlined,
            size: 18,
            color: expired ? AppColors.error : AppColors.teal,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              expired ? expiredLabel : '$heldLabel $formattedCountdown $minutesLabel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: expired ? AppColors.error : AppColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AppColors.teal : AppColors.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: selected ? AppColors.teal : AppColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.teal : AppColors.border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
