import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';

/// Route: '/login' — phone entry, OTP request.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static final _phonePattern = RegExp(r'^(10|11|12|15)[0-9]{8}$');

  final _phoneController = TextEditingController();
  bool _isValid = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final isValid = _phonePattern.hasMatch(_phoneController.text.trim());
    if (isValid != _isValid) {
      setState(() => _isValid = isValid);
    }
  }

  Future<void> _submit() async {
    if (!_isValid || _isSubmitting) return;

    final phone = '+20${_phoneController.text.trim()}';
    setState(() => _isSubmitting = true);

    try {
      await ref.read(authControllerProvider.notifier).requestOtp(phone);
      if (!mounted) return;
      context.push('/otp', extra: phone);
    } on DioException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.ar.errors.generic)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.ar.errors.generic)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.ar;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Image.asset(
                        'assets/logos/hagez_logo_transparent.png',
                        height: 88,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      strings.auth.welcomeTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.auth.welcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      strings.auth.enterPhone,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      maxLength: 10,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      decoration: InputDecoration(
                        prefixText: '+20 ',
                        prefixStyle: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                        hintText: strings.auth.phonePlaceholder,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isValid && !_isSubmitting ? _submit : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(strings.auth.sendOtp),
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(text: '${strings.auth.byProceeding} '),
                          TextSpan(
                            text: strings.auth.termsOfService,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                          ),
                          TextSpan(text: ' ${strings.auth.and} '),
                          TextSpan(
                            text: strings.auth.privacyPolicy,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
