import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import '../storage/secure_storage.dart';

class AuthRepository {
  AuthRepository(this._dio);
  final Dio _dio;

  /// POST /auth/otp/request — always returns a generic success message,
  /// regardless of whether the phone is registered (no enumeration).
  Future<void> requestOtp(String phone) async {
    await _dio.post('/auth/otp/request', data: {'phone': phone});
  }

  /// POST /auth/otp/verify — on success, persists both tokens and returns
  /// the authenticated user.
  Future<HagezUser> verifyOtp({required String phone, required String otp}) async {
    final response = await _dio.post('/auth/otp/verify', data: {'phone': phone, 'otp': otp});
    final data = response.data as Map<String, dynamic>;
    await SecureStorage.instance.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return HagezUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // best-effort — clear local tokens regardless of network state
    }
    await SecureStorage.instance.clear();
  }

  Future<bool> hasSession() async => (await SecureStorage.instance.getAccessToken()) != null;
}

final authRepository = AuthRepository(ApiClient.instance.dio);
