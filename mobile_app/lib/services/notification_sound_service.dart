import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSoundService {
  static const String _messageEnabledKey = 'airtext.message-sound-enabled';
  static const String _callEnabledKey = 'airtext.call-sound-enabled';
  static const String _messageToneKey = 'airtext.message-tone';
  static const String _callToneKey = 'airtext.call-tone';
  static final AudioPlayer _player = AudioPlayer();
  static Timer? _callTimer;

  static const Map<String, int> messageTones = {
    'Chime': 880,
    'Modern ping': 1175,
    'Soft echo': 660,
  };

  static Future<bool> isMessageSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_messageEnabledKey) ?? true;
  }

  static Future<bool> isCallSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_callEnabledKey) ?? true;
  }

  static Future<String> getMessageTone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_messageToneKey) ?? 'Chime';
  }

  static Future<String> getCallTone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_callToneKey) ?? 'Soft echo';
  }

  static Future<void> setMessageSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_messageEnabledKey, value);
  }

  static Future<void> setCallSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_callEnabledKey, value);
    if (!value) await stopCallSound();
  }

  static Future<void> setMessageTone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_messageToneKey, value);
  }

  static Future<void> setCallTone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_callToneKey, value);
  }

  static Future<void> playMessageSound({bool preview = false}) async {
    if (!preview && !await isMessageSoundEnabled()) return;
    final tone = await getMessageTone();
    await _play(tone, const Duration(milliseconds: 220));
  }

  static Future<void> startCallSound() async {
    if (!await isCallSoundEnabled()) return;
    await stopCallSound();
    await _play(await getCallTone(), const Duration(milliseconds: 720));
    _callTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_playCallTone());
    });
  }

  static Future<void> stopCallSound() async {
    _callTimer?.cancel();
    _callTimer = null;
    await _player.stop();
  }

  static Future<void> _playCallTone() async {
    if (!await isCallSoundEnabled()) {
      await stopCallSound();
      return;
    }
    await _play(await getCallTone(), const Duration(milliseconds: 720));
  }

  static Future<void> _play(String tone, Duration duration) async {
    try {
      final frequency = messageTones[tone] ?? messageTones['Chime']!;
      await _player.stop();
      await _player.play(
        BytesSource(_wave(frequency, duration), mimeType: 'audio/wav'),
      );
    } on Exception {
      // Audio is best-effort; notification delivery must not depend on playback.
    }
  }

  static Uint8List _wave(int frequency, Duration duration) {
    const sampleRate = 16000;
    final sampleCount = sampleRate * duration.inMilliseconds ~/ 1000;
    final data = ByteData(44 + sampleCount * 2);
    data.setUint32(0, 0x46464952, Endian.little);
    data.setUint32(4, 36 + sampleCount * 2, Endian.little);
    data.setUint32(8, 0x45564157, Endian.little);
    data.setUint32(12, 0x20746d66, Endian.little);
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    data.setUint32(36, 0x61746164, Endian.little);
    data.setUint32(40, sampleCount * 2, Endian.little);

    for (var index = 0; index < sampleCount; index++) {
      final progress = index / sampleCount;
      final fade = math.min(1.0, math.min(progress * 18, (1 - progress) * 18));
      final sample = math.sin(2 * math.pi * frequency * index / sampleRate);
      data.setInt16(
        44 + index * 2,
        (sample * fade * 10000).round(),
        Endian.little,
      );
    }

    return data.buffer.asUint8List();
  }
}
