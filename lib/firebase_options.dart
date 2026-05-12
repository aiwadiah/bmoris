import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDu1Fn7ZrI2-BIN0MT1zm6ZaqP_GXuMGoU',
    appId: '1:94172327212:web:bmoris-web-app',
    messagingSenderId: '94172327212',
    projectId: 'bmoris-55fdb',
    authDomain: 'bmoris-55fdb.firebaseapp.com',
    storageBucket: 'bmoris-55fdb.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDu1Fn7ZrI2-BIN0MT1zm6ZaqP_GXuMGoU',
    appId: '1:94172327212:android:e52a8544d2d5458c565089',
    messagingSenderId: '94172327212',
    projectId: 'bmoris-55fdb',
    storageBucket: 'bmoris-55fdb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDu1Fn7ZrI2-BIN0MT1zm6ZaqP_GXuMGoU',
    appId: '1:94172327212:ios:e52a8544d2d5458c565089',
    messagingSenderId: '94172327212',
    projectId: 'bmoris-55fdb',
    storageBucket: 'bmoris-55fdb.firebasestorage.app',
    iosBundleId: 'com.example.bmoris',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDu1Fn7ZrI2-BIN0MT1zm6ZaqP_GXuMGoU',
    appId: '1:94172327212:ios:e52a8544d2d5458c565089',
    messagingSenderId: '94172327212',
    projectId: 'bmoris-55fdb',
    storageBucket: 'bmoris-55fdb.firebasestorage.app',
    iosBundleId: 'com.example.bmoris',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDu1Fn7ZrI2-BIN0MT1zm6ZaqP_GXuMGoU',
    appId: '1:94172327212:windows:bmoris-windows-app',
    messagingSenderId: '94172327212',
    projectId: 'bmoris-55fdb',
    storageBucket: 'bmoris-55fdb.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDu1Fn7ZrI2-BIN0MT1zm6ZaqP_GXuMGoU',
    appId: '1:94172327212:linux:bmoris-linux-app',
    messagingSenderId: '94172327212',
    projectId: 'bmoris-55fdb',
    storageBucket: 'bmoris-55fdb.firebasestorage.app',
  );
}
