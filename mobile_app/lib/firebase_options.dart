import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _messagingSenderId = String.fromEnvironment(
  'FIREBASE_MESSAGING_SENDER_ID',
);
const _androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

FirebaseOptions? get airTextFirebaseOptions {
  if (_apiKey.isEmpty || _projectId.isEmpty || _messagingSenderId.isEmpty) {
    return null;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android when _androidAppId.isNotEmpty => FirebaseOptions(
      apiKey: _apiKey,
      appId: _androidAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
    ),
    TargetPlatform.iOS when _iosAppId.isNotEmpty && _iosBundleId.isNotEmpty =>
      FirebaseOptions(
        apiKey: _apiKey,
        appId: _iosAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        iosBundleId: _iosBundleId,
      ),
    _ => null,
  };
}
