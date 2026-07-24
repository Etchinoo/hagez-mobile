import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'env.dart';

/// Thrown when a request fails after an exhausted refresh attempt — callers
/// should route to the login screen.
class SessionExpiredException implements Exception {}

/// Dio wrapper: injects the access token, and on a 401 attempts exactly one
/// refresh-and-retry (via POST /auth/refresh) before giving up. Mirrors the
/// API's token model from the security-hardening PR: access and refresh
/// tokens are distinct (separate secret + `type` claim server-side), so a
/// refresh call here is the only way to mint a new access token.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.instance.getAccessToken();
        if (token != null && !options.path.contains('/auth/')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isAuthEndpoint = error.requestOptions.path.contains('/auth/');
        if (error.response?.statusCode == 401 && !isAuthEndpoint && !_isRetry(error.requestOptions)) {
          try {
            final refreshed = await _refresh();
            if (refreshed) {
              final retryOptions = error.requestOptions;
              retryOptions.extra['retried'] = true;
              final token = await SecureStorage.instance.getAccessToken();
              retryOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(retryOptions);
              return handler.resolve(response);
            }
          } catch (_) {
            // fall through to SessionExpiredException below
          }
          await SecureStorage.instance.clear();
          return handler.reject(DioException(
            requestOptions: error.requestOptions,
            error: SessionExpiredException(),
          ));
        }
        handler.next(error);
      },
    ));
  }

  static final instance = ApiClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;

  bool _isRetry(RequestOptions options) => options.extra['retried'] == true;

  Future<bool> _refresh() async {
    final refreshToken = await SecureStorage.instance.getRefreshToken();
    if (refreshToken == null) return false;

    final response = await Dio(BaseOptions(baseUrl: Env.apiBaseUrl)).post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final newAccessToken = response.data['access_token'] as String?;
    if (newAccessToken == null) return false;

    await SecureStorage.instance.saveTokens(accessToken: newAccessToken, refreshToken: refreshToken);
    return true;
  }
}
