import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_state.dart';
import '../../core/models/user.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';

/// Route: '/profile' — user info, language toggle, notification prefs, logout.
///
/// NOTE (follow-up, not full locale wiring): the language toggle below is
/// visual only for this pass. It flips a local segmented control but does
/// not change AppStrings.of(...) app-wide or persist a preference — that
/// requires routing every screen's string lookup through a shared locale
/// provider, which is out of scope here. Same for the notification switch:
/// there is currently no API endpoint to read/write notification
/// preferences, so it's a local-only toggle with no backend call.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Visual-only state — see class doc comment above.
  late String _languageChoice = 'ar';
  bool _notificationsEnabled = true;
  bool _initializedFromUser = false;
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final strings = AppStrings.ar;

    if (authState is AuthAuthenticated) {
      if (!_initializedFromUser) {
        _languageChoice = authState.user.languagePref == 'en' ? 'en' : 'ar';
        _initializedFromUser = true;
      }
      return _buildProfile(context, strings, authState.user);
    }

    if (authState is AuthUnauthenticated) {
      // This screen should only be reachable when logged in; if we land
      // here unauthenticated (e.g. session expired elsewhere), bounce to
      // login instead of showing a broken profile.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    // AuthLoading — session restore still in flight.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _buildProfile(BuildContext context, AppStrings strings, HagezUser user) {
    final trimmedName = user.fullName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName.substring(0, 1) : '?';

    return Scaffold(
      appBar: AppBar(title: Text(strings.profile.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: ClipOval(
                child: user.profilePhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user.profilePhotoUrl!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _initialAvatar(initial),
                        errorWidget: (context, url, error) => _initialAvatar(initial),
                      )
                    : _initialAvatar(initial),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName.isNotEmpty ? user.fullName : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Center(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  user.phone,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildLanguageRow(strings),
                    const Divider(height: 24),
                    _buildNotificationsRow(strings),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: _loggingOut ? null : () => _handleLogout(context),
              icon: _loggingOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                    )
                  : const Icon(Icons.logout, color: AppColors.error),
              label: Text(strings.auth.logout, style: const TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  'Hagez • v1.0.0',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _initialAvatar(String initial) {
    return Container(
      width: 96,
      height: 96,
      color: AppColors.teal,
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  Widget _buildLanguageRow(AppStrings strings) {
    return Row(
      children: [
        const Icon(Icons.language, color: AppColors.navy),
        const SizedBox(width: 12),
        Expanded(
          child: Text(strings.profile.language, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'ar', label: Text(strings.profile.arabic)),
            ButtonSegment(value: 'en', label: Text(strings.profile.english)),
          ],
          selected: {_languageChoice},
          onSelectionChanged: (selection) {
            // Visual only — does not change the app's active locale yet.
            // See follow-up note in the class doc comment above.
            setState(() => _languageChoice = selection.first);
          },
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }

  Widget _buildNotificationsRow(AppStrings strings) {
    return Row(
      children: [
        const Icon(Icons.notifications_outlined, color: AppColors.navy),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.profile.notifications, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                strings.profile.notificationsSubtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: _notificationsEnabled,
          activeThumbColor: AppColors.teal,
          onChanged: (value) {
            // Visual only — no backend endpoint exists yet to persist this.
            // See follow-up note in the class doc comment above.
            setState(() => _notificationsEnabled = value);
          },
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    setState(() => _loggingOut = true);
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } on SessionExpiredException {
      // Already effectively logged out server-side; fall through to /login.
    } catch (_) {
      // Best-effort: AuthRepository.logout() already swallows network
      // errors and clears local tokens regardless, so this should be rare.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.ar.errors.generic)),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
    if (context.mounted) context.go('/login');
  }
}
