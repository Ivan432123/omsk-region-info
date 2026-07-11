import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// ВАЖНО: этот файл — ШАБЛОН.
/// Реальные значения должны быть сгенерированы командой:
///   flutterfire configure --project=<ваш-firebase-project-id>
/// Не публикуйте реальные API-ключи в открытый репозиторий без ограничений
/// на использование ключа в Firebase Console (App Check / API restrictions).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Веб-платформа пока не сконфигурирована для ОМСКРЕГИОН ИНФО.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions не сконфигурирован для этой платформы.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_ANDROID_API_KEY',
    appId: 'REPLACE_WITH_YOUR_ANDROID_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'omsk-region-info',
    storageBucket: 'omsk-region-info.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_YOUR_IOS_API_KEY',
    appId: 'REPLACE_WITH_YOUR_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
    projectId: 'omsk-region-info',
    storageBucket: 'omsk-region-info.appspot.com',
    iosBundleId: 'ru.omskregion.info',
  );
}
