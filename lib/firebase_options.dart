// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDIeptUqYQ9oxH6jlDt-BKoaR0VN2Mqtxw',
    appId: '1:313954033619:android:abeddfa68b4960e92e1926',
    messagingSenderId: '313954033619',
    projectId: 'consolidacion-5b340',
    storageBucket: 'consolidacion-5b340.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBdQ_eYJzCtZpuNnrafXEGRaK7SKb5GKjA',
    appId: '1:313954033619:ios:f498539ed16661db2e1926',
    messagingSenderId: '313954033619',
    projectId: 'consolidacion-5b340',
    storageBucket: 'consolidacion-5b340.firebasestorage.app',
    iosBundleId: 'com.example.formularioApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA0AmSY4J1AIi8_Iu5dagJzwgjAhEO3uvM',
    appId: '1:313954033619:web:910e9f3f4be0cc1c2e1926',
    messagingSenderId: '313954033619',
    projectId: 'consolidacion-5b340',
    authDomain: 'consolidacion-5b340.firebaseapp.com',
    storageBucket: 'consolidacion-5b340.firebasestorage.app',
  );

}