import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';

const _resendCooldownSeconds = 30;

/// Route: '/otp' (extra: phone as String) — 6-digit OTP entry + verify.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _resendTimer;

  bool _isVerifying = false;
  bool _isResending = false;
  bool _isComplete = false;
  int _secondsLeft = _resendCooldownSeconds;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
    _startResendCooldown();
  }

  void _onOtpChanged() {
    final isComplete = _otpController.text.trim().length == 6;
    if (isComplete != _isComplete || _errorText != null) {
      setState(() {
        _isComplete = isComplete;
        _errorText = null;
      });
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authControllerProvider.notifier).requestOtp(widget.phone);
      if (!mounted) return;
      _startResendCooldown();
    } on DioException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.ar.errors.generic)),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(phone: widget.phone, otp: otp);
      if (!mounted) return;
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 401) {
        setState(() => _errorText = AppStrings.ar.auth.invalidOtp);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.ar.errors.generic)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.ar.errors.generic)),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ar;
    final canResend = _secondsLeft <= 0 && !_isResending;

    return Scaffold(
      appBar: AppBar(title: Text(strings.auth.enterOtp)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${strings.auth.otpSentTo} ${widget.phone}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 16,
                  color: AppColors.navy,
                ),
                decoration: InputDecoration(
                  hintText: strings.auth.otpPlaceholder,
                  counterText: '',
                  errorText: _errorText,
                ),
                onChanged: (value) {
                  if (value.length == 6) _verify();
                },
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isComplete && !_isVerifying ? _verify : null,
                child: _isVerifying
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(strings.auth.verifyOtp),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: canResend ? _resend : null,
                  child: Text(
                    canResend ? strings.auth.resendOtp : strings.auth.resendIn(_secondsLeft),
                    style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
