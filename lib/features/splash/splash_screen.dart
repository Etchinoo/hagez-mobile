import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';

/// Route: '/' — auth gate. Redirects to /home or /login once the stored
/// session state resolves. STUB: replace with branded splash art/animation.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState is AuthAuthenticated) {
        context.go('/home');
      } else if (authState is AuthUnauthenticated) {
        context.go('/login');
      }
    });

    return const Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('حاجز', style: TextStyle(fontFamily: 'Cairo', fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
