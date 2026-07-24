import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final HagezUser user;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthLoading()) {
    _restore();
  }

  Future<void> _restore() async {
    final hasSession = await authRepository.hasSession();
    // Note: this only checks token PRESENCE, not validity. The API client's
    // 401 interceptor handles expiry transparently on the first real request;
    // a SessionExpiredException bubbling up should call [logout] below.
    state = hasSession ? const AuthAuthenticated(_placeholderUser) : const AuthUnauthenticated();
  }

  Future<void> requestOtp(String phone) => authRepository.requestOtp(phone);

  Future<void> verifyOtp({required String phone, required String otp}) async {
    final user = await authRepository.verifyOtp(phone: phone, otp: otp);
    state = AuthAuthenticated(user);
  }

  Future<void> logout() async {
    await authRepository.logout();
    state = const AuthUnauthenticated();
  }

  // TODO(next screen agent): replace with a real GET /users/me call on
  // restore so a resumed session has full user details, not a placeholder.
  static const _placeholderUser = HagezUser(
    id: '',
    phone: '',
    fullName: '',
    languagePref: 'ar',
  );
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
