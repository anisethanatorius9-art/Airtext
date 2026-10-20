import 'package:local_auth/local_auth.dart';

class AppLockService {
  static final LocalAuthentication _authentication = LocalAuthentication();

  static Future<bool> authenticateUser() async {
    try {
      if (!await _authentication.isDeviceSupported()) return false;
      if ((await _authentication.getAvailableBiometrics()).isEmpty) {
        return false;
      }

      return await _authentication.authenticate(
        localizedReason: 'Authenticate to unlock Air app',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
