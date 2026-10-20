import 'package:shared_preferences/shared_preferences.dart';

class StorageSettingsService {
  static const String _keyPhotos = 'auto_download_photos';
  static const String _keyVideos = 'auto_download_videos';
  static const String _keyStickers = 'auto_download_stickers';
  static const String _keyVoiceNotes = 'auto_download_voice';
  static const String _keyUseLessDataForCalls = 'storage_use_less_data_calls';
  static const String _keyUploadQuality = 'storage_upload_quality';
  static const String _keyAutoDownloadQuality = 'storage_auto_download_quality';
  static const String _keyMobileDataDownloads = 'storage_mobile_data_downloads';
  static const String _keyWifiDownloads = 'storage_wifi_downloads';
  static const String _keyRoamingDownloads = 'storage_roaming_downloads';

  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'use_less_data_for_calls': prefs.getBool(_keyUseLessDataForCalls) ?? false,
      'upload_quality': prefs.getString(_keyUploadQuality) ?? 'hd',
      'auto_download_quality':
          prefs.getString(_keyAutoDownloadQuality) ?? 'auto',
      'mobile_data_downloads':
          prefs.getString(_keyMobileDataDownloads) ?? 'photos',
      'wifi_downloads': prefs.getString(_keyWifiDownloads) ?? 'all',
      'roaming_downloads': prefs.getString(_keyRoamingDownloads) ?? 'none',
      'auto_download_photos': prefs.getBool(_keyPhotos) ?? true,
      'auto_download_videos': prefs.getBool(_keyVideos) ?? true,
      'auto_download_stickers': prefs.getBool(_keyStickers) ?? false,
      'auto_download_voice': prefs.getBool(_keyVoiceNotes) ?? true,
    };
  }

  static Future<void> saveSettings({
    required bool useLessDataForCalls,
    required String uploadQuality,
    required String autoDownloadQuality,
    required String mobileDataDownloads,
    required String wifiDownloads,
    required String roamingDownloads,
    required bool autoDownloadPhotos,
    required bool autoDownloadVideos,
    required bool autoDownloadStickers,
    required bool autoDownloadVoice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseLessDataForCalls, useLessDataForCalls);
    await prefs.setString(_keyUploadQuality, uploadQuality);
    await prefs.setString(_keyAutoDownloadQuality, autoDownloadQuality);
    await prefs.setString(_keyMobileDataDownloads, mobileDataDownloads);
    await prefs.setString(_keyWifiDownloads, wifiDownloads);
    await prefs.setString(_keyRoamingDownloads, roamingDownloads);
    await prefs.setBool(_keyPhotos, autoDownloadPhotos);
    await prefs.setBool(_keyVideos, autoDownloadVideos);
    await prefs.setBool(_keyStickers, autoDownloadStickers);
    await prefs.setBool(_keyVoiceNotes, autoDownloadVoice);
  }

  static Future<void> setPhotosDownload(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPhotos, value);
  }

  static Future<bool> getPhotosDownload() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPhotos) ?? true;
  }

  static Future<void> setVideosDownload(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVideos, value);
  }

  static Future<bool> getVideosDownload() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVideos) ?? true;
  }

  static Future<void> setStickersDownload(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStickers, value);
  }

  static Future<bool> getStickersDownload() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyStickers) ?? false;
  }

  static Future<void> setVoiceNotesDownload(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceNotes, value);
  }

  static Future<bool> getVoiceNotesDownload() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVoiceNotes) ?? true;
  }
}
