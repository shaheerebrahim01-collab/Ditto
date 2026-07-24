import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

// Backend base URL. Override at build/run time with:
//   flutter run --dart-define=API_BASE_URL=https://api.ditto.example.com
class Env {
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && Platform.isAndroid) {
      // Android emulator's alias for the host machine's localhost.
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
