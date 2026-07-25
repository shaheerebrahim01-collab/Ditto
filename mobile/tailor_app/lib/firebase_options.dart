import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase Auth is project-wide (same "ditto-713d5" project as
/// customer_app), so the web client config is safe to reuse verbatim here.
/// Android has no registered app for this package (com.ditto.app.tailor_app)
/// yet — run `flutterfire configure` against this project once that's
/// needed; until then this only supports running on web.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android — '
          'run `flutterfire configure` for com.ditto.app.tailor_app first.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCssgF3G_afAzRVG3V9pkbZruWN_2RIM-Y',
    appId: '1:209876187617:web:3a6576d4bda25c7595faa0',
    messagingSenderId: '209876187617',
    projectId: 'ditto-713d5',
    authDomain: 'ditto-713d5.firebaseapp.com',
    storageBucket: 'ditto-713d5.firebasestorage.app',
    measurementId: 'G-3RZ2NG52MB',
  );
}
