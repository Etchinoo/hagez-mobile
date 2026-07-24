import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// API base URL, overridable at build/run time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000/v1
///
/// Defaults follow the same guidance as the old Expo app's .env.example:
/// Android emulator can't reach the host via localhost, so it uses the
/// special 10.0.2.2 alias; everything else (iOS simulator, web, desktop)
/// uses localhost directly.
class Env {
  Env._();

  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:3000/v1';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000/v1';
    return 'http://localhost:3000/v1';
  }
}
