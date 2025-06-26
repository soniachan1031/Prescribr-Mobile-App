// Modified from FlutterFire CLI generated file
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return getWebOptions();
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return getAndroidOptions();
      case TargetPlatform.iOS:
        return getIOSOptions();
      case TargetPlatform.macOS:
        return getMacOSOptions();
      case TargetPlatform.windows:
        return getWindowsOptions();
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
  
  // Use getters to access API keys from environment variables
  static String get apiKey => dotenv.env['FIREBASE_API_KEY'] ?? 'DEFAULT_API_KEY';
  
  // Web platform options
  static FirebaseOptions getWebOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:458709881473:web:14a8fff97c6ab974493380',
      messagingSenderId: '458709881473',
      projectId: 'prescribr-sc',
      authDomain: 'prescribr-sc.firebaseapp.com',
      storageBucket: 'prescribr-sc.firebasestorage.app',
      measurementId: 'G-W7VSLFDR6F',
    );
  }

  // Android platform options
  static FirebaseOptions getAndroidOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:458709881473:android:6a58eb088b40a653d8ecdf',
      messagingSenderId: '458709881473',
      projectId: 'prescribr-sc',
      storageBucket: 'prescribr-sc.firebasestorage.app',
    );
  }

  // iOS platform options
  static FirebaseOptions getIOSOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:458709881473:ios:512b1106b525e4bdd8ecdf',
      messagingSenderId: '458709881473',
      projectId: 'prescribr-sc',
      storageBucket: 'prescribr-sc.firebasestorage.app',
      iosBundleId: 'ca.prescribr.app',
    );
  }
  
  // macOS platform options
  static FirebaseOptions getMacOSOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:458709881473:ios:512b1106b525e4bdd8ecdf',
      messagingSenderId: '458709881473',
      projectId: 'prescribr-sc',
      storageBucket: 'prescribr-sc.firebasestorage.app',
      iosBundleId: 'ca.prescribr.app',
    );
  }
  
  // Windows platform options
  static FirebaseOptions getWindowsOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: '1:458709881473:web:14a8fff97c6ab974493380',
      messagingSenderId: '458709881473',
      projectId: 'prescribr-sc',
      authDomain: 'prescribr-sc.firebaseapp.com',
      storageBucket: 'prescribr-sc.firebasestorage.app',
      measurementId: 'G-W7VSLFDR6F',
    );
  }
}
