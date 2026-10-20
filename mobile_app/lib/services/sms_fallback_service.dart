import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms/flutter_sms.dart';

enum SmsDispatchResult { sentBySim, composerOpened }

class SmsFallbackService {
  static const MethodChannel _smsChannel = MethodChannel('airtext/sms');

  static Future<SmsDispatchResult> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _smsChannel.invokeMethod<bool>('sendSms', {
        'number': phoneNumber,
        'message': message,
      });
      return SmsDispatchResult.sentBySim;
    }

    final opened = await launchSms(number: phoneNumber, message: message);
    if (!opened) {
      throw PlatformException(
        code: 'sms_unavailable',
        message: 'No SMS app is available on this device.',
      );
    }
    return SmsDispatchResult.composerOpened;
  }
}
