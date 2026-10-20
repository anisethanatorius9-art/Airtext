import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dynamic_app_icon_flutter_plus/dynamic_app_icon_flutter_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_app/active_video_call_screen.dart';
import 'package:mobile_app/airtext_call_client.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'services/cache_manager_service.dart';
import 'services/sms_fallback_service.dart';
import 'services/storage_settings_service.dart';
import 'screens/auth/email_otp_screen.dart';
import 'screens/auth/email_register_screen.dart';
import 'screens/auth/auth_screen_frame.dart';
import 'screens/auth/phone_verify_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/app_lock_service.dart';
import 'services/notification_sound_service.dart';
import 'video_call_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final options = airTextFirebaseOptions;
  if (options == null) return;
  if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
}

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const MethodChannel _screenPrivacyChannel = MethodChannel(
  'airtext/screen_privacy',
);
const MethodChannel _deviceInfoChannel = MethodChannel('airtext/device_info');

Future<void> _setScreenPrivacy(bool enabled) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _screenPrivacyChannel.invokeMethod<void>('setEnabled', {
      'enabled': enabled,
    });
  } on MissingPluginException {
    debugPrint('Screen privacy channel unavailable.');
  } on PlatformException catch (error) {
    debugPrint('Screen privacy channel unavailable: ${error.code}');
  }
}

const _ink = Color(0xFF18231E);
const _green = Color(0xFF008069);
const _paper = Color(0xFFF3F0E8);
const _lightPanel = Color(0xFFFCFBF7);
const _lightPanelRaised = Color(0xFFE8EEEA);
const _lightBorder = Color(0xFFD7DFDA);
const _lightMuted = Color(0xFF5F6D67);
const _obsidian = Color(0xFF101714);
const _panel = Color(0xFF18211D);
const _panelRaised = Color(0xFF202A25);
const _line = Color(0xFF35413B);
const _mint = Color(0xFF77D2A5);
const _silver = Color(0xFFB8C1BC);
const _nexusBackground = Color(0xFF101714);
const _nexusPanel = Color(0xFF18211D);
const _nexusBorder = Color(0xFF35413B);
const _nexusText = Color(0xFFE7ECE9);
const _nexusMuted = Color(0xFFB0BBB4);
const _nexusAccent = Color(0xFFB9E878);
const _languageCodes = <String, String>{
  'Kiswahili': 'sw',
  'English': 'en',
  'French': 'fr',
  'Spanish': 'es',
  'Arabic': 'ar',
  'Mandarin Chinese': 'zh',
  'Portuguese': 'pt',
  'Hindi': 'hi',
  'Russian': 'ru',
  'German': 'de',
  'Japanese': 'ja',
  'Korean': 'ko',
  'Italian': 'it',
  'Turkish': 'tr',
  'Vietnamese': 'vi',
  'Urdu': 'ur',
  'Persian': 'fa',
  'Polish': 'pl',
  'Ukrainian': 'uk',
  'Dutch': 'nl',
  'Greek': 'el',
  'Bengali': 'bn',
  'Punjabi': 'pa',
  'Javanese': 'jv',
  'Telugu': 'te',
  'Marathi': 'mr',
  'Tamil': 'ta',
  'Gujarati': 'gu',
  'Hausa': 'ha',
  'Yoruba': 'yo',
  'Igbo': 'ig',
  'Amharic': 'am',
  'Zulu': 'zu',
  'Xhosa': 'xh',
  'Somali': 'so',
  'Malay / Indonesian': 'id',
  'Tagalog': 'tl',
  'Thai': 'th',
  'Hungarian': 'hu',
  'Czech': 'cs',
  'Swedish': 'sv',
  'Danish': 'da',
  'Finnish': 'fi',
  'Norwegian': 'no',
  'Romanian': 'ro',
  'Hebrew': 'he',
  'Bulgarian': 'bg',
  'Serbian': 'sr',
  'Croatian': 'hr',
  'Slovak': 'sk',
};
const _appTranslations = <String, Map<String, String>>{
  'fr': {
    'Chats': 'Discussions',
    'Updates': 'Actualités',
    'Shop': 'Boutique',
    'Settings': 'Paramètres',
    'Profile': 'Profil',
    'ACCOUNT': 'COMPTE',
    'Photo, username and about': 'Photo, nom d’utilisateur et bio',
    'Account': 'Compte',
    'Registration, sign out and data': 'Inscription, déconnexion et données',
    'DISPLAY': 'AFFICHAGE',
    'Appearance': 'Apparence',
    'Chat Theme': 'Thème des discussions',
    'MESSAGING': 'MESSAGERIE',
    'GSM & SMS Protocol': 'Protocole GSM et SMS',
    'Manage offline messaging': 'Gérer la messagerie hors ligne',
    'Notifications': 'Notifications',
    'Message & call tones': 'Sons des messages et des appels',
    'Storage and data': 'Stockage et données',
    'Chats, media, auto-download': 'Discussions, médias, téléchargement auto.',
    'PRIVACY & ACCESS': 'CONFIDENTIALITÉ ET ACCÈS',
    'Privacy': 'Confidentialité',
    'Last seen, profile visibility': 'Dernière présence, visibilité du profil',
    'Accessibility': 'Accessibilité',
    'Text size, motion and display': 'Taille du texte, animations et affichage',
    'App language': 'Langue de l’application',
    'Tap to change app language': 'Touchez pour changer la langue',
    'Invite friend': 'Inviter un ami',
    'Share AirText with a friend': 'Partager AirText avec un ami',
    'MORE': 'PLUS',
    'Help & feedback': 'Aide et commentaires',
    'Reports, policy and support': 'Signalements, règles et assistance',
    'LANGUAGE': 'LANGUE',
    'New conversation': 'Nouvelle discussion',
    'Close command sphere': 'Fermer les commandes',
    'Open command sphere': 'Ouvrir les commandes',
    'More options': 'Plus d’options',
    'Search or start a new chat': 'Rechercher ou démarrer une discussion',
    'New message': 'Nouveau message',
    'Contacts': 'Contacts',
    'Calls': 'Appels',
    'All': 'Tout',
    'Unread': 'Non lus',
    'No chats found': 'Aucune discussion trouvée',
    'Marketplace': 'Place de marché',
    'Payments are not connected': 'Les paiements ne sont pas connectés',
    'Wallet': 'Portefeuille',
    'Not connected': 'Non connecté',
    'Search products and services': 'Rechercher des produits et services',
    'Browse': 'Parcourir',
    'Installed': 'Installés',
    'SMS Bots': 'Bots SMS',
    'Gateways': 'Passerelles',
    'Templates': 'Modèles',
    'No products found': 'Aucun produit trouvé',
    'No installed services': 'Aucun service installé',
    'Payments are not configured. No credits were added.':
        'Les paiements ne sont pas configurés. Aucun crédit n’a été ajouté.',
    'Payments are not configured. No purchase was made.':
        'Les paiements ne sont pas configurés. Aucun achat n’a été effectué.',
    'RECENT UPDATES': 'ACTUALITÉS RÉCENTES',
    'VIEWED UPDATES': 'ACTUALITÉS CONSULTÉES',
    'COMMUNITIES': 'COMMUNAUTÉS',
    'My Status': 'Mon statut',
    'Sign in to see status updates from your contacts.':
        'Connectez-vous pour voir les actualités de vos contacts.',
    'No recent updates.': 'Aucune actualité récente.',
    'Sign in to share status updates.':
        'Connectez-vous pour partager des actualités.',
    'Communities': 'Communautés',
    'Refresh updates': 'Actualiser les actualités',
    'STATUS': 'STATUT',
    'Tap to add a status update': 'Touchez pour ajouter un statut',
  },
  'sw': {
    'Chats': 'Mazungumzo',
    'Updates': 'Taarifa',
    'Shop': 'Duka',
    'Settings': 'Mipangilio',
    'Profile': 'Wasifu',
    'ACCOUNT': 'AKAUNTI',
    'Photo, username and about': 'Picha, jina la mtumiaji na maelezo',
    'Account': 'Akaunti',
    'Registration, sign out and data': 'Usajili, kutoka na data',
    'DISPLAY': 'MWONEKANO',
    'Appearance': 'Mwonekano',
    'Chat Theme': 'Mandhari ya mazungumzo',
    'MESSAGING': 'UJUMBE',
    'GSM & SMS Protocol': 'Itifaki ya GSM na SMS',
    'Manage offline messaging': 'Dhibiti ujumbe bila intaneti',
    'Notifications': 'Arifa',
    'Message & call tones': 'Sauti za ujumbe na simu',
    'Storage and data': 'Hifadhi na data',
    'Chats, media, auto-download': 'Mazungumzo, media, upakuaji wa kiotomatiki',
    'PRIVACY & ACCESS': 'FARAGHA NA UFIKIAJI',
    'Privacy': 'Faragha',
    'Last seen, profile visibility': 'Mara ya mwisho, mwonekano wa wasifu',
    'Accessibility': 'Ufikivu',
    'Text size, motion and display': 'Ukubwa wa maandishi, mwendo na mwonekano',
    'App language': 'Lugha ya programu',
    'Tap to change app language': 'Gusa kubadilisha lugha ya programu',
    'Invite friend': 'Alika rafiki',
    'Share AirText with a friend': 'Shiriki AirText na rafiki',
    'MORE': 'ZAIDI',
    'Help & feedback': 'Msaada na maoni',
    'Reports, policy and support': 'Ripoti, sera na usaidizi',
    'LANGUAGE': 'LUGHA',
    'New conversation': 'Mazungumzo mapya',
    'Close command sphere': 'Funga menyu ya amri',
    'Open command sphere': 'Fungua menyu ya amri',
    'More options': 'Chaguo zaidi',
    'Search or start a new chat': 'Tafuta au anza mazungumzo mapya',
    'New message': 'Ujumbe mpya',
    'Contacts': 'Anwani',
    'Calls': 'Simu',
    'All': 'Zote',
    'Unread': 'Hazijasomwa',
    'No chats found': 'Hakuna mazungumzo yaliyopatikana',
    'Marketplace': 'Soko',
    'Payments are not connected': 'Malipo hayajaunganishwa',
    'Wallet': 'Pochi',
    'Not connected': 'Haijaunganishwa',
    'Search products and services': 'Tafuta bidhaa na huduma',
    'Browse': 'Vinjari',
    'Installed': 'Zilizosakinishwa',
    'SMS Bots': 'Boti za SMS',
    'Gateways': 'Milango ya mtandao',
    'Templates': 'Violezo',
    'No products found': 'Hakuna bidhaa zilizopatikana',
    'No installed services': 'Hakuna huduma zilizosakinishwa',
    'Payments are not configured. No credits were added.':
        'Malipo hayajawekwa. Salio halijaongezwa.',
    'Payments are not configured. No purchase was made.':
        'Malipo hayajawekwa. Hakuna ununuzi uliofanyika.',
    'RECENT UPDATES': 'TAARIFA ZA HIVI KARIBUNI',
    'VIEWED UPDATES': 'TAARIFA ULIZOANGALIA',
    'COMMUNITIES': 'JAMII',
    'My Status': 'Hali yangu',
    'Sign in to see status updates from your contacts.':
        'Ingia kuona taarifa za hali kutoka kwa anwani zako.',
    'No recent updates.': 'Hakuna taarifa mpya.',
    'Sign in to share status updates.': 'Ingia kushiriki taarifa za hali.',
    'Communities': 'Jamii',
    'Refresh updates': 'Onyesha upya taarifa',
    'STATUS': 'HALI',
    'Tap to add a status update': 'Gusa kuongeza taarifa ya hali',
  },
  'zh': {
    'Chats': '聊天',
    'Updates': '动态',
    'Shop': '商店',
    'Settings': '设置',
    'Profile': '个人资料',
    'ACCOUNT': '账户',
    'Photo, username and about': '头像、用户名和个人简介',
    'Account': '账户',
    'Registration, sign out and data': '注册、退出登录和数据',
    'DISPLAY': '显示',
    'Appearance': '外观',
    'Chat Theme': '聊天主题',
    'MESSAGING': '消息',
    'GSM & SMS Protocol': 'GSM 和短信协议',
    'Manage offline messaging': '管理离线消息',
    'Notifications': '通知',
    'Message & call tones': '消息和通话铃声',
    'Storage and data': '存储和数据',
    'Chats, media, auto-download': '聊天、媒体和自动下载',
    'PRIVACY & ACCESS': '隐私与权限',
    'Privacy': '隐私',
    'Last seen, profile visibility': '最后上线时间和个人资料可见性',
    'Accessibility': '无障碍功能',
    'Text size, motion and display': '文字大小、动态效果和显示',
    'App language': '应用语言',
    'Tap to change app language': '点击以更改应用语言',
    'Invite friend': '邀请好友',
    'Share AirText with a friend': '与好友分享 AirText',
    'MORE': '更多',
    'Help & feedback': '帮助与反馈',
    'Reports, policy and support': '举报、政策和支持',
    'LANGUAGE': '语言',
    'New conversation': '新建聊天',
    'Close command sphere': '关闭快捷菜单',
    'Open command sphere': '打开快捷菜单',
    'More options': '更多选项',
    'Search or start a new chat': '搜索或开始新聊天',
    'New message': '新消息',
    'Contacts': '联系人',
    'Calls': '通话',
    'All': '全部',
    'Unread': '未读',
    'No chats found': '没有找到聊天',
    'Marketplace': '应用市场',
    'Payments are not connected': '尚未连接支付服务',
    'Wallet': '钱包',
    'Not connected': '未连接',
    'Search products and services': '搜索产品和服务',
    'Browse': '浏览',
    'Installed': '已安装',
    'SMS Bots': '短信机器人',
    'Gateways': '网关',
    'Templates': '模板',
    'No products found': '没有找到产品',
    'No installed services': '没有已安装的服务',
    'Payments are not configured. No credits were added.': '尚未配置支付，未添加任何余额。',
    'Payments are not configured. No purchase was made.': '尚未配置支付，未完成任何购买。',
    'RECENT UPDATES': '最新动态',
    'VIEWED UPDATES': '已查看的动态',
    'COMMUNITIES': '社群',
    'My Status': '我的状态',
    'Sign in to see status updates from your contacts.': '登录后查看联系人的状态动态。',
    'No recent updates.': '暂无最新动态。',
    'Sign in to share status updates.': '登录后分享状态动态。',
    'Communities': '社群',
    'Refresh updates': '刷新动态',
    'STATUS': '状态',
    'Tap to add a status update': '点击添加状态动态',
  },
};

String _appCopy(BuildContext context, String english) {
  final languageCode = Localizations.localeOf(context).languageCode;
  return _appTranslations[languageCode]?[english] ?? english;
}

const _reverbHost = String.fromEnvironment(
  'AIRTEXT_REVERB_HOST',
  defaultValue: '10.0.2.2',
);
const _reverbKey = String.fromEnvironment('AIRTEXT_REVERB_KEY');
const _reverbPort = int.fromEnvironment(
  'AIRTEXT_REVERB_PORT',
  defaultValue: 8080,
);
const _reverbUseTls = bool.fromEnvironment('AIRTEXT_REVERB_TLS');

Uri? _telephoneUri(String number) {
  final cleanNumber = number.replaceAll(RegExp(r'[^0-9+*#]'), '');
  if (cleanNumber.replaceAll(RegExp(r'\D'), '').length < 7) return null;
  return Uri(scheme: 'tel', path: cleanNumber);
}

String _languageCodeFor(String language) {
  final normalized = language.trim().toLowerCase();
  for (final entry in _languageCodes.entries) {
    if (normalized.startsWith(entry.key.toLowerCase())) return entry.value;
  }
  return 'en';
}

Future<bool> _openVoiceCallScreen(
  BuildContext context,
  String number, {
  String contactName = '',
}) async {
  final uri = _telephoneUri(number);
  if (uri == null) return false;

  if (!context.mounted) return false;

  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => _PhoneCallPage(
        contactName: contactName.trim().isNotEmpty
            ? contactName.trim()
            : 'Contact',
        phoneNumber: uri.path,
      ),
    ),
  );
  return true;
}

enum AirTextLogoStyle { mark, monogram, signal }

class AirTextAppearance extends ChangeNotifier {
  static const String largeTextKey = 'airtext.accessibility.large-text';
  static const String reducedMotionKey = 'airtext.accessibility.reduced-motion';
  static const String highContrastKey = 'airtext.accessibility.high-contrast';
  static const String appLockKey = 'airtext.security.app-lock';
  static const String chatLockKey = 'airtext.security.chat-lock';
  static const String disappearingMessagesKey =
      'airtext.privacy.disappearing-messages';

  ThemeMode themeMode = ThemeMode.system;
  String language = 'Kiswahili (Tanzania)';
  AirTextLogoStyle logoStyle = AirTextLogoStyle.mark;
  Color chatAccent = _mint;
  Uint8List? chatWallpaper;
  bool largeText = false;
  bool reducedMotion = true;
  bool highContrast = false;
  bool appLockEnabled = false;
  bool chatLockEnabled = false;
  bool disappearingMessagesEnabled = false;
  bool messageSoundsEnabled = true;
  bool callSoundsEnabled = true;
  String messageTone = 'Chime';
  String callTone = 'Soft echo';
  bool isLoaded = false;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    language =
        preferences.getString('airtext.language') ?? 'Kiswahili (Tanzania)';
    final themeName = preferences.getString('airtext.appearance.theme');
    themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeName,
      orElse: () => ThemeMode.system,
    );
    final logoName = preferences.getString('airtext.appearance.logo');
    logoStyle = AirTextLogoStyle.values.firstWhere(
      (style) => style.name == logoName,
      orElse: () => AirTextLogoStyle.mark,
    );
    final accentValue = preferences.getInt('airtext.appearance.chat-accent');
    if (accentValue != null) chatAccent = Color(accentValue);
    final wallpaper = preferences.getString(
      'airtext.appearance.chat-wallpaper',
    );
    chatWallpaper = wallpaper == null ? null : base64Decode(wallpaper);
    largeText = preferences.getBool(largeTextKey) ?? false;
    reducedMotion = preferences.getBool(reducedMotionKey) ?? true;
    highContrast = preferences.getBool(highContrastKey) ?? false;
    appLockEnabled = preferences.getBool(appLockKey) ?? false;
    chatLockEnabled = preferences.getBool(chatLockKey) ?? false;
    disappearingMessagesEnabled =
        preferences.getBool(disappearingMessagesKey) ?? false;
    messageSoundsEnabled =
        await NotificationSoundService.isMessageSoundEnabled();
    callSoundsEnabled = await NotificationSoundService.isCallSoundEnabled();
    messageTone = await NotificationSoundService.getMessageTone();
    callTone = await NotificationSoundService.getCallTone();
    isLoaded = true;
    notifyListeners();
  }

  Locale get locale => Locale(_languageCodeFor(language));

  Future<void> setLanguage(String value) async {
    language = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('airtext.language', value);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('airtext.appearance.theme', value.name);
  }

  Future<void> setBooleanPreference(String key, bool value) async {
    switch (key) {
      case largeTextKey:
        largeText = value;
      case reducedMotionKey:
        reducedMotion = value;
      case highContrastKey:
        highContrast = value;
      case appLockKey:
        appLockEnabled = value;
      case chatLockKey:
        chatLockEnabled = value;
      case disappearingMessagesKey:
        disappearingMessagesEnabled = value;
      default:
        throw ArgumentError.value(key, 'key', 'Unknown boolean preference');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
    notifyListeners();
  }

  Future<void> setMessageSoundsEnabled(bool value) async {
    await NotificationSoundService.setMessageSoundEnabled(value);
    messageSoundsEnabled = value;
    notifyListeners();
  }

  Future<void> setCallSoundsEnabled(bool value) async {
    await NotificationSoundService.setCallSoundEnabled(value);
    callSoundsEnabled = value;
    notifyListeners();
  }

  Future<void> setMessageTone(String value) async {
    await NotificationSoundService.setMessageTone(value);
    messageTone = value;
    notifyListeners();
  }

  Future<void> setCallTone(String value) async {
    await NotificationSoundService.setCallTone(value);
    callTone = value;
    notifyListeners();
  }

  Future<void> setLogoStyle(AirTextLogoStyle value) async {
    logoStyle = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('airtext.appearance.logo', value.name);
  }

  Future<void> setChatAccent(Color value) async {
    chatAccent = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      'airtext.appearance.chat-accent',
      value.toARGB32(),
    );
  }

  Future<void> setChatWallpaper(Uint8List? value) async {
    chatWallpaper = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    if (value == null) {
      await preferences.remove('airtext.appearance.chat-wallpaper');
    } else {
      await preferences.setString(
        'airtext.appearance.chat-wallpaper',
        base64Encode(value),
      );
    }
  }
}

class AirTextApiException implements Exception {
  const AirTextApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

abstract interface class ApiTokenStore {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<void> deleteToken();
}

class SecureApiTokenStore implements ApiTokenStore {
  SecureApiTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'airtext.api-token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}

class AirTextApi {
  AirTextApi({http.Client? client, ApiTokenStore? tokenStore, String? baseUrl})
    : _client = client ?? http.Client(),
      _tokenStore = tokenStore ?? SecureApiTokenStore(),
      _baseUri = Uri.parse(
        baseUrl ??
            const String.fromEnvironment(
              'AIRTEXT_API_URL',
              defaultValue: 'http://10.0.2.2:8000/api',
            ),
      );

  final http.Client _client;
  final ApiTokenStore _tokenStore;
  final Uri _baseUri;
  static const _legacyTokenKey = 'airtext.api-token';
  String? _token;

  bool get isAuthenticated => _token != null;

  Uri get apiBaseUri => _baseUri;

  String? get accessToken => _token;

  Future<Map<String, dynamic>> getCurrentUser() => _request('GET', '/me');

  Future<void> clearToken() async {
    _token = null;
    await _tokenStore.deleteToken();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_legacyTokenKey);
  }

  Future<void> restoreToken() async {
    try {
      _token = await _tokenStore.readToken();
      if (_token != null) return;

      final preferences = await SharedPreferences.getInstance();
      final legacyToken = preferences.getString(_legacyTokenKey);
      if (legacyToken == null) return;

      await _tokenStore.writeToken(legacyToken);
      await preferences.remove(_legacyTokenKey);
      _token = legacyToken;
    } catch (_) {
      throw const AirTextApiException(
        'Secure token storage is unavailable on this device.',
        0,
      );
    }
  }

  Future<void> requestOtp(String email) async {
    await _request('POST', '/auth/otp/request', body: {'email': email});
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    String? name,
  }) async {
    final response = await _request(
      'POST',
      '/auth/otp/verify',
      body: {
        'email': email,
        'code': code,
        ...?name == null ? null : {'name': name},
      },
    );
    final token = response['token'] as String?;
    if (token != null) {
      try {
        await _tokenStore.writeToken(token);
      } catch (_) {
        throw const AirTextApiException(
          'Could not securely store the sign-in session on this device.',
          0,
        );
      }
      _token = token;
    }
    return response;
  }

  Future<Map<String, dynamic>> updateProfile(String name) async {
    final response = await _request('PUT', '/me/profile', body: {'name': name});
    return response['user'] as Map<String, dynamic>;
  }

  Future<void> updateProfilePhoto(Uint8List bytes) async {
    final request =
        http.MultipartRequest(
            'POST',
            _baseUri.replace(path: '${_baseUri.path}/me/profile-photo'),
          )
          ..headers['Accept'] = 'application/json'
          ..files.add(
            http.MultipartFile.fromBytes(
              'photo',
              bytes,
              filename: 'profile.jpg',
            ),
          );
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      throw AirTextApiException(
        decoded['message'] as String? ?? 'Could not save profile photo.',
        response.statusCode,
      );
    }
  }

  Future<void> sendPresenceHeartbeat() async {
    await _request('POST', '/me/presence');
  }

  Future<Map<String, dynamic>> getUserPreferences() async {
    final response = await _request('GET', '/me/preferences');
    return response['preferences'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSmsGatewayPreferences({
    Map<String, Object?>? storageSettings,
    Map<String, Object?>? messagingSettings,
  }) async {
    final body = <String, Object?>{};
    if (storageSettings != null) body['storage_settings'] = storageSettings;
    if (messagingSettings != null) {
      body['messaging_settings'] = messagingSettings;
    }
    final response = await _request('PUT', '/me/preferences', body: body);
    return response['preferences'] as Map<String, dynamic>;
  }

  Future<List<AirTextContact>> getContacts() async {
    final response = await _request('GET', '/contacts');
    return (response['data'] as List<dynamic>)
        .map((item) => AirTextContact.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<AirTextContact> createContact({
    required String name,
    required String phoneNumber,
    required String payloadPrefix,
  }) async {
    final response = await _request(
      'POST',
      '/contacts',
      body: {
        'name': name,
        'phone_number': phoneNumber,
        'payload_prefix': payloadPrefix,
      },
    );
    return AirTextContact.fromApi(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getSmsGateway() =>
      _request('GET', '/me/sms-gateway');

  Future<String> testSmsGateway() async {
    final response = await _request('POST', '/me/sms-gateway/test');
    return response['message'] as String? ?? 'Gateway connection verified.';
  }

  Future<Map<String, dynamic>> getStorageSummary() =>
      _request('GET', '/me/storage-summary');

  Future<ChatMessage> recordLocalSms({
    required int conversationId,
    required String body,
    required String payloadPrefix,
  }) async {
    final response = await _request(
      'POST',
      '/conversations/$conversationId/messages/local-sms',
      body: {'body': body, 'payload_prefix': payloadPrefix},
    );
    return ChatMessage.fromApi(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateUserPreferences({
    String? appLanguage,
    String? lastSeenVisibility,
    String? profilePictureVisibility,
    String? aboutVisibility,
    String? linksVisibility,
    String? statusVisibility,
    bool? disappearingMessages,
  }) async {
    final body = <String, Object?>{};
    if (appLanguage != null) body['app_language'] = appLanguage;
    if (lastSeenVisibility != null) {
      body['last_seen_visibility'] = lastSeenVisibility;
    }
    if (profilePictureVisibility != null) {
      body['profile_picture_visibility'] = profilePictureVisibility;
    }
    if (aboutVisibility != null) body['about_visibility'] = aboutVisibility;
    if (linksVisibility != null) body['links_visibility'] = linksVisibility;
    if (statusVisibility != null) body['status_visibility'] = statusVisibility;
    if (disappearingMessages != null) {
      body['disappearing_messages'] = disappearingMessages;
    }

    final response = await _request('PUT', '/me/preferences', body: body);
    return response['preferences'] as Map<String, dynamic>;
  }

  Future<void> requestPhoneOtp(String phoneNumber) async {
    await _request(
      'POST',
      '/auth/phone/otp/request',
      body: {'phone_number': phoneNumber},
    );
  }

  Future<void> verifyPhoneOtp({
    required String phoneNumber,
    required String code,
  }) async {
    final response = await _request(
      'POST',
      '/auth/phone/otp/verify',
      body: {'phone_number': phoneNumber, 'code': code},
    );
    final token = response['token'] as String?;
    if (token == null) return;
    try {
      await _tokenStore.writeToken(token);
    } catch (_) {
      throw const AirTextApiException(
        'Could not securely store the sign-in session on this device.',
        0,
      );
    }
    _token = token;
  }

  Future<Map<String, dynamic>> verifyPhoneLoginOtp({
    required String challenge,
    required String code,
  }) async {
    final response = await _request(
      'POST',
      '/auth/phone/otp/verify-login',
      body: {'challenge': challenge, 'code': code},
    );
    final token = response['token'] as String;
    try {
      await _tokenStore.writeToken(token);
    } catch (_) {
      throw const AirTextApiException(
        'Could not securely store the sign-in session on this device.',
        0,
      );
    }
    _token = token;
    return response['user'] as Map<String, dynamic>;
  }

  Future<List<ChatConversation>> getConversations() async {
    final response = await _request('GET', '/conversations');
    return (response['data'] as List<dynamic>)
        .map((item) => ChatConversation.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> syncPhoneContacts(List<String> phoneNumbers) async {
    final response = await _request(
      'PUT',
      '/me/contacts',
      body: {'phone_numbers': phoneNumbers},
    );
    return response['matched_contacts'] as int? ?? 0;
  }

  Future<ChatConversation> createConversation({
    String? email,
    String? phoneNumber,
    String? name,
  }) async {
    final response = await _request(
      'POST',
      '/conversations',
      body: {
        ...?email == null ? null : {'recipient_email': email},
        ...?phoneNumber == null ? null : {'phone_number': phoneNumber},
        ...?name == null ? null : {'name': name},
      },
    );
    return ChatConversation.fromApi(response['data'] as Map<String, dynamic>);
  }

  Future<ChatMessage> sendMessage(
    int conversationId,
    String body, {
    bool viewOnce = false,
  }) async {
    final response = await _request(
      'POST',
      '/conversations/$conversationId/messages',
      body: {'body': body, 'view_once': viewOnce},
    );
    return ChatMessage.fromApi(response['data'] as Map<String, dynamic>);
  }

  Future<ChatMessage> sendVoiceMessage(
    int conversationId,
    String path, {
    bool viewOnce = false,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            _baseUri.replace(
              path: '${_baseUri.path}/conversations/$conversationId/messages',
            ),
          )
          ..headers['Accept'] = 'application/json'
          ..fields['message_type'] = 'voice'
          ..fields['view_once'] = viewOnce.toString()
          ..files.add(await http.MultipartFile.fromPath('media', path));
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AirTextApiException(
        decoded['message'] as String? ?? 'Could not send voice message.',
        response.statusCode,
      );
    }
    return ChatMessage.fromApi(decoded['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> openViewOnceMessage(
    int conversationId,
    int messageId,
  ) => _request(
    'POST',
    '/conversations/$conversationId/messages/$messageId/view-once',
  );

  Future<String> downloadVoiceMessage(String mediaPath) async {
    final uri = _baseUri.replace(path: '${_baseUri.path}$mediaPath');
    final request = http.Request('GET', uri)..headers['Accept'] = 'audio/*';
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AirTextApiException(
        'This voice message is no longer available.',
        response.statusCode,
      );
    }
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/airtext-playback-${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  Future<void> setTyping(
    int conversationId,
    bool isTyping, {
    String activity = 'typing',
  }) async {
    await _request(
      'POST',
      '/conversations/$conversationId/typing',
      body: {'is_typing': isTyping, 'activity': activity},
    );
  }

  Future<String?> getTypingStatus(int conversationId) async {
    final response = await _request(
      'GET',
      '/conversations/$conversationId/typing',
    );
    return (response['is_typing'] as bool? ?? false)
        ? response['activity'] as String?
        : null;
  }

  Future<String> translateMessage({
    required int conversationId,
    required int messageId,
    required String targetLanguage,
  }) async {
    final response = await _request(
      'POST',
      '/conversations/$conversationId/messages/$messageId/translate',
      body: {'target_language': targetLanguage},
    );
    return response['translation'] as String;
  }

  Future<void> markConversationRead(int conversationId) async {
    await _request('POST', '/conversations/$conversationId/read');
  }

  Future<void> registerPushToken(
    String token,
    String platform, {
    String messageTone = 'Chime',
  }) async {
    await _request(
      'POST',
      '/device-tokens',
      body: {'token': token, 'platform': platform, 'message_tone': messageTone},
    );
  }

  Future<void> removePushToken(String token) async {
    await _request('DELETE', '/device-tokens', body: {'token': token});
  }

  Future<Map<String, dynamic>> createGroupCall(List<int> participantIds) async {
    final response = await _request(
      'POST',
      '/group-calls',
      body: {'participant_ids': participantIds},
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGroupCallToken(String callId) async {
    final response = await _request('GET', '/group-calls/$callId/token');
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptGroupCall(String callId) async {
    final response = await _request('POST', '/group-calls/$callId/accept');
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> declineGroupCall(String callId) async {
    await _request('POST', '/group-calls/$callId/decline');
  }

  Future<void> leaveGroupCall(String callId) async {
    await _request('POST', '/group-calls/$callId/leave');
  }

  Future<List<Map<String, dynamic>>> getActiveGroupCalls() async {
    final response = await _request('GET', '/group-calls/active');
    return (response['data'] as List<dynamic>)
        .map((call) => Map<String, dynamic>.from(call as Map))
        .toList();
  }

  Future<List<_StatusUpdate>> _getStatuses() async {
    final response = await _request('GET', '/statuses');
    return (response['data'] as List<dynamic>)
        .map((item) => _StatusUpdate.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<_StatusUpdate> _createTextStatus(
    String text, {
    bool viewOnce = false,
  }) async {
    final response = await _request(
      'POST',
      '/statuses',
      body: {'body': text, 'view_once': viewOnce, 'screenshot_protected': true},
    );
    return _StatusUpdate.fromApi(response['data'] as Map<String, dynamic>);
  }

  Future<_StatusUpdate> _createPhotoStatus(
    XFile photo, {
    bool viewOnce = false,
  }) async {
    final uri = _baseUri.replace(path: '${_baseUri.path}/statuses');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..fields['view_once'] = viewOnce.toString()
      ..fields['screenshot_protected'] = 'true'
      ..files.add(await http.MultipartFile.fromPath('media', photo.path));
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AirTextApiException(
          decoded['message'] as String? ?? 'Could not publish the status.',
          response.statusCode,
        );
      }
      return _StatusUpdate.fromApi(decoded['data'] as Map<String, dynamic>);
    } on AirTextApiException {
      debugPrint('Conversation activity update failed.');
      rethrow;
    } on http.ClientException {
      throw const AirTextApiException('Could not reach the Air app server.', 0);
    }
  }

  Future<void> _markStatusViewed(int statusId) async {
    await _request('POST', '/statuses/$statusId/view');
  }

  Future<List<Map<String, dynamic>>> getStatusViewers(int statusId) async {
    final response = await _request('GET', '/statuses/$statusId/viewers');
    return (response['data'] as List<dynamic>)
        .map((viewer) => Map<String, dynamic>.from(viewer as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getStatusLikers(int statusId) async {
    final response = await _request('GET', '/statuses/$statusId/likes');
    return (response['data'] as List<dynamic>)
        .map((liker) => Map<String, dynamic>.from(liker as Map))
        .toList();
  }

  Future<Map<String, dynamic>> likeStatus(int statusId) async {
    return _request('POST', '/statuses/$statusId/like');
  }

  Future<Map<String, dynamic>> unlikeStatus(int statusId) async {
    return _request('DELETE', '/statuses/$statusId/like');
  }

  Future<void> logout() async {
    try {
      if (_token != null) {
        await _request('DELETE', '/auth/token');
      }
    } finally {
      await clearToken();
    }
  }

  Future<void> deleteAccount() async {
    await _request('DELETE', '/me');
    await clearToken();
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final uri = _baseUri.replace(path: '${_baseUri.path}$path');
    final savedLanguage = (await SharedPreferences.getInstance()).getString(
      'airtext.language',
    );
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': _languageCodeFor(
        savedLanguage ?? 'Kiswahili (Tanzania)',
      ),
      ...?body == null ? null : {'Content-Type': 'application/json'},
      ...?_token == null ? null : {'Authorization': 'Bearer $_token'},
    };

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errors = decoded['errors'] as Map<String, dynamic>?;
        final firstError = errors?.values.firstOrNull;
        final message =
            decoded['message'] as String? ??
            (firstError is List && firstError.isNotEmpty
                ? firstError.first as String
                : 'Air app request failed (${response.statusCode}).');
        throw AirTextApiException(message, response.statusCode);
      }
      return decoded;
    } on AirTextApiException {
      rethrow;
    } on http.ClientException {
      throw const AirTextApiException(
        'Could not reach Air app. Check the server address and connection.',
        0,
      );
    } on FormatException {
      throw const AirTextApiException(
        'The Air app server returned invalid data.',
        0,
      );
    }
  }
}

void main() => runApp(const AirTextApp());

class AirTextApp extends StatefulWidget {
  const AirTextApp({super.key, this.api});

  final AirTextApi? api;

  @override
  State<AirTextApp> createState() => _AirTextAppState();
}

class _AirTextAppState extends State<AirTextApp> {
  final _appearance = AirTextAppearance();

  @override
  void initState() {
    super.initState();
    _appearance.load();
  }

  @override
  void dispose() {
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appearance,
      builder: (context, _) => MaterialApp(
        title: 'Air app',
        debugShowCheckedModeBanner: false,
        locale: _appearance.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: _buildTheme(Brightness.light, _appearance.highContrast),
        darkTheme: _buildTheme(Brightness.dark, _appearance.highContrast),
        themeMode: _appearance.themeMode,
        builder: (context, child) {
          final brightness = Theme.of(context).brightness;
          final mediaQuery = MediaQuery.of(context);
          final systemScale = mediaQuery.textScaler.scale(1.0);
          final requestedScale = _appearance.largeText && systemScale < 1.3
              ? 1.3
              : systemScale;
          return CupertinoTheme(
            data: CupertinoThemeData(
              brightness: brightness,
              primaryColor: _appearance.chatAccent,
              scaffoldBackgroundColor: brightness == Brightness.dark
                  ? _obsidian
                  : _paper,
            ),
            child: MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(requestedScale),
                disableAnimations: _appearance.reducedMotion,
                highContrast: _appearance.highContrast,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: ChatsPage(
          api: widget.api ?? AirTextApi(),
          appearance: _appearance,
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness, bool highContrast) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = highContrast
        ? (isDark
              ? const ColorScheme.highContrastDark()
              : const ColorScheme.highContrastLight())
        : ColorScheme.fromSeed(
            seedColor: isDark ? _mint : _green,
            brightness: brightness,
            surface: isDark ? _obsidian : _lightPanel,
          );
    return ThemeData(
      platform: TargetPlatform.iOS,
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? _obsidian : _paper,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _obsidian : _lightPanel,
        foregroundColor: isDark ? Colors.white : _ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? _panel : _lightPanel,
        indicatorColor: isDark
            ? const Color(0xFF26372F)
            : const Color(0xFFD9EEE5),
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class AirTextLogo extends StatelessWidget {
  const AirTextLogo({
    required this.style,
    this.size = 36,
    this.foregroundColor = Colors.white,
    super.key,
  });

  final AirTextLogoStyle style;
  final double size;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (style == AirTextLogoStyle.mark) return AuthBrandMark(size: size);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF123B50) : const Color(0xFFDFEEE6),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: switch (style) {
        AirTextLogoStyle.mark => const SizedBox.shrink(),
        AirTextLogoStyle.monogram => Text(
          'A',
          style: TextStyle(
            color: isDark ? Colors.white : _green,
            fontSize: size * 0.58,
            fontWeight: FontWeight.w800,
          ),
        ),
        AirTextLogoStyle.signal => Icon(
          CupertinoIcons.antenna_radiowaves_left_right,
          color: isDark ? Colors.white : _green,
          size: size * 0.6,
        ),
      },
    );
  }
}

class ChatMessage {
  ChatMessage(
    this.text,
    this.time, {
    this.isMine = false,
    this.sentAt,
    this.expiresAt,
    this.reaction,
    this.status = 'sent',
    this.backendId,
    this.messageType = 'text',
    this.mediaUrl,
    this.viewOnce = false,
    this.viewOncePending = false,
    this.viewedAt,
  });

  String text;
  final String time;
  final bool isMine;
  final DateTime? sentAt;
  final DateTime? expiresAt;
  String? reaction;
  String status;
  final int? backendId;
  final String messageType;
  String? mediaUrl;
  final bool viewOnce;
  bool viewOncePending;
  DateTime? viewedAt;
  String? translation;

  factory ChatMessage.fromApi(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['sent_at'] as String? ?? '');
    return ChatMessage(
      json['body'] as String? ?? '',
      timestamp == null ? 'Now' : _formatMessageTime(timestamp.toLocal()),
      isMine: json['is_mine'] as bool? ?? false,
      sentAt: timestamp?.toLocal(),
      status: json['status'] as String? ?? 'sent',
      backendId: json['id'] as int?,
      messageType: json['message_type'] as String? ?? 'text',
      mediaUrl: json['media_url'] as String?,
      viewOnce: json['view_once'] as bool? ?? false,
      viewOncePending: json['view_once_pending'] as bool? ?? false,
      viewedAt: DateTime.tryParse(json['viewed_at'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '')
          ?.toLocal(),
    );
  }
}

class ChatConversation {
  ChatConversation({
    required this.name,
    required this.initials,
    required this.status,
    required this.time,
    required this.unread,
    required this.color,
    required this.messages,
    this.phoneNumber = '',
    this.disappearingDuration = 'Off',
    this.isBlocked = false,
    this.isReported = false,
    this.shareLastSeen = true,
    this.readReceipts = true,
    this.backendId,
    this.recipientEmail,
    this.isSmsRoute = false,
    this.payloadPrefix = 'MSG:',
    this.counterpartUserId,
    this.profilePhotoUrl,
    this.isOnline = false,
    this.lastSeenAt,
  });

  final String name;
  final String initials;
  String status;
  final String time;
  int unread;
  final Color color;
  final List<ChatMessage> messages;
  final String phoneNumber;
  String disappearingDuration;
  bool isBlocked;
  bool isReported;
  bool shareLastSeen;
  bool readReceipts;
  final int? backendId;
  final int? counterpartUserId;
  final String? recipientEmail;
  final bool isSmsRoute;
  final String payloadPrefix;
  final String? profilePhotoUrl;
  bool isOnline;
  DateTime? lastSeenAt;

  String get preview => messages.isEmpty ? '' : messages.last.text;

  factory ChatConversation.fromApi(Map<String, dynamic> json) {
    final messages = (json['messages'] as List<dynamic>? ?? [])
        .map((item) => ChatMessage.fromApi(item as Map<String, dynamic>))
        .toList();
    final name = json['name'] as String? ?? 'Air app contact';
    final isSms = json['route'] == 'sms';
    final isOnline = json['is_online'] as bool? ?? false;
    final lastSeen = DateTime.tryParse(json['last_seen_at'] as String? ?? '')
        ?.toLocal();
    return ChatConversation(
      name: name,
      initials: name
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part[0].toUpperCase())
          .join(),
      status: isSms
          ? 'SMS contact'
          : isOnline
          ? 'Online'
          : lastSeen == null
          ? 'Air app contact'
          : 'Last seen ${_formatMessageTime(lastSeen)}',
      time: messages.isEmpty ? 'New' : messages.last.time,
      unread: json['unread_count'] as int? ?? 0,
      color: const Color(0xFF26372F),
      messages: messages,
      phoneNumber: json['phone_number'] as String? ?? '',
      backendId: json['id'] as int?,
      counterpartUserId: json['counterpart_user_id'] as int?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: DateTime.tryParse(json['last_seen_at'] as String? ?? ''),
      recipientEmail: json['email'] as String?,
      isSmsRoute: isSms,
      payloadPrefix: json['payload_prefix'] as String? ?? 'MSG:',
    );
  }
}

String _formatMessageTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
}

bool _isSameChatDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _chatDateLabel(BuildContext context, DateTime date) {
  final localDate = date.toLocal();
  final today = DateTime.now();
  if (_isSameChatDay(localDate, today)) return 'Today';
  if (_isSameChatDay(localDate, today.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  return MaterialLocalizations.of(context).formatMediumDate(localDate);
}

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key, required this.api, required this.appearance});

  final AirTextApi api;
  final AirTextAppearance appearance;

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  late final AirTextApi _api = widget.api;
  Timer? _conversationSyncTimer;
  AirTextCallClient? _callClient;
  StreamSubscription<AirTextCallSignal>? _callSignalSubscription;
  StreamSubscription<int>? _messageUpdateSubscription;
  StreamSubscription<String>? _pushTokenSubscription;
  StreamSubscription<RemoteMessage>? _pushOpenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  String? _incomingCallDialogId;
  bool _pushSetupComplete = false;
  bool _appLocked = false;
  bool _chatLocked = false;
  bool _authenticationInProgress = false;
  bool _initialLockStateHandled = false;
  bool _hasLoadedRemoteConversations = false;
  final Set<int> _playedIncomingMessageIds = {};
  final List<ChatConversation> _conversations = [
    ChatConversation(
      name: 'Mariam Hassan',
      initials: 'MH',
      status: 'Air app contact',
      time: '10:42 AM',
      unread: 2,
      color: const Color(0xFFD6E9DE),
      phoneNumber: '+255 718 220 901',
      messages: [
        ChatMessage('Habari! Umefika salama?', '10:38 AM'),
        ChatMessage('Ndio, nimefika. Asante!', '10:42 AM', isMine: true),
      ],
    ),
    ChatConversation(
      name: 'Juma K.',
      initials: 'JK',
      status: 'SMS contact',
      time: 'Yesterday',
      unread: 0,
      color: const Color(0xFFF5DFCC),
      phoneNumber: '+255 712 884 102',
      messages: [ChatMessage('The studio address is on its way.', 'Yesterday')],
    ),
    ChatConversation(
      name: '+255 782 328 215',
      initials: '+2',
      status: 'SMS contact',
      time: 'Mon',
      unread: 0,
      color: const Color(0xFFDDE4F2),
      phoneNumber: '+255 782 328 215',
      messages: [ChatMessage('Ni vizuri sana, asante!', 'Mon')],
    ),
    ChatConversation(
      name: 'Air app updates',
      initials: 'A',
      status: 'Channel',
      time: 'Sun',
      unread: 0,
      color: const Color(0xFFDCEBE8),
      messages: [
        ChatMessage('Payload protocol updates and service news', 'Sun'),
      ],
    ),
  ];
  late final List<ChatConversation> _offlineConversations =
      List<ChatConversation>.of(_conversations);

  String _filter = 'All';
  int _selectedTab = 0;
  bool _commandExpanded = false;
  bool _sessionRestored = false;
  bool _signedOutLocked = false;
  List<AirTextContact> _contacts = [
    AirTextContact(
      name: 'Mariam Hassan',
      phoneNumber: '+255 718 220 901',
      isAirTextUser: true,
    ),
    AirTextContact(
      name: 'Juma K.',
      phoneNumber: '+255 712 884 102',
      isAirTextUser: false,
    ),
    AirTextContact(
      name: 'Neema Studio',
      phoneNumber: '+255 763 100 445',
      isAirTextUser: true,
    ),
    AirTextContact(
      name: 'Unknown number',
      phoneNumber: '+255 782 328 215',
      isAirTextUser: false,
    ),
  ];
  String _displayName = 'Air app User';
  String _username = '@airapp';
  String _about = 'Available';
  Uint8List? _profileImage;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.appearance.addListener(_onAppearanceChanged);
    _onAppearanceChanged();
    _loadSavedContacts();
    _loadSavedProfile();
    _restoreRemoteSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.appearance.removeListener(_onAppearanceChanged);
    _searchController.dispose();
    _conversationSyncTimer?.cancel();
    unawaited(_stopCallSignaling());
    unawaited(_stopPushNotifications());
    unawaited(NotificationSoundService.stopCallSound());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_authenticationInProgress) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        unawaited(DynamicAppIconFlutterPlus.applyPendingIcon());
      }
      if (widget.appearance.appLockEnabled) _appLocked = true;
      if (_selectedTab == 0 && widget.appearance.chatLockEnabled) {
        _chatLocked = true;
      }
      unawaited(NotificationSoundService.stopCallSound());
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      if (_api.isAuthenticated) unawaited(_sendPresenceHeartbeatSafely());
      if (_appLocked) unawaited(_authenticateAppLock());
    }
  }

  void _onAppearanceChanged() {
    if (!widget.appearance.isLoaded) return;
    if (!_initialLockStateHandled) {
      _initialLockStateHandled = true;
      if (widget.appearance.appLockEnabled) {
        _appLocked = true;
        unawaited(_authenticateAppLock());
      }
      _chatLocked = widget.appearance.chatLockEnabled;
      if (mounted) setState(() {});
      return;
    }

    if (!widget.appearance.appLockEnabled) _appLocked = false;
    if (widget.appearance.chatLockEnabled) _chatLocked = true;
    if (mounted) setState(() {});
  }

  Future<void> _authenticateAppLock() async {
    if (_authenticationInProgress) return;
    _authenticationInProgress = true;
    final authenticated = await AppLockService.authenticateUser();
    _authenticationInProgress = false;
    if (!mounted) return;
    setState(() => _appLocked = !authenticated);
  }

  Future<bool> _authenticateChatLock() async {
    final authenticated = await AppLockService.authenticateUser();
    if (authenticated && mounted) setState(() => _chatLocked = false);
    return authenticated;
  }

  Future<void> _restoreRemoteSession() async {
    await _api.restoreToken();
    if (!_api.isAuthenticated) {
      if (!mounted) return;
      setState(() {
        _signedOutLocked = true;
        _sessionRestored = true;
      });
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('airtext.onboarding-complete', true);
    try {
      final user = await _api.getCurrentUser();
      await preferences.setString('airtext.account', jsonEncode(user));
      await _loadRemoteConversations();
      if (!mounted) return;
      await preferences.remove('airtext.signed-out');
      setState(() {
        _signedOutLocked = false;
        _sessionRestored = true;
        _displayName = user['name'] as String? ?? _displayName;
        _username = user['email'] as String? ?? _username;
        _profilePhotoUrl = user['profile_photo_url'] as String?;
      });
      _startConversationSync();
      await _startCallSignaling(user['id'] as int);
    } on AirTextApiException catch (error) {
      if (error.statusCode == 401) {
        await _api.clearToken();
        await preferences.setBool('airtext.signed-out', true);
        if (mounted) {
          setState(() {
            _signedOutLocked = true;
            _sessionRestored = true;
          });
        }
      } else {
        final cachedAccountJson = preferences.getString('airtext.account');
        Map<String, dynamic>? cachedAccount;
        if (cachedAccountJson != null) {
          try {
            final decoded = jsonDecode(cachedAccountJson);
            if (decoded is Map<String, dynamic>) cachedAccount = decoded;
          } on FormatException {
            await preferences.remove('airtext.account');
          }
        }
        if (!mounted) return;
        setState(() {
          _signedOutLocked = false;
          _sessionRestored = true;
          _displayName = cachedAccount?['name'] as String? ?? _displayName;
          _username = cachedAccount?['email'] as String? ?? _username;
        });
        _startConversationSync();
      }
    }
  }

  Future<void> _loadRemoteConversations() async {
    final conversations = await _api.getConversations();
    if (!mounted) return;
    final previousMessageIds = _conversations
        .expand((conversation) => conversation.messages)
        .map((message) => message.backendId)
        .whereType<int>()
        .toSet();
    if (_hasLoadedRemoteConversations) {
      for (final conversation in conversations) {
        for (final message in conversation.messages) {
          final messageId = message.backendId;
          if (!message.isMine &&
              messageId != null &&
              !previousMessageIds.contains(messageId) &&
              _playedIncomingMessageIds.add(messageId)) {
            unawaited(NotificationSoundService.playMessageSound());
          }
        }
      }
    }
    _hasLoadedRemoteConversations = true;
    setState(() {
      _conversations
        ..clear()
        ..addAll(conversations);
    });
  }

  Future<void> _refreshConversationsFromRealtime() async {
    try {
      await _loadRemoteConversations();
    } on AirTextApiException catch (error) {
      if (error.statusCode == 401) {
        _conversationSyncTimer?.cancel();
        await _api.clearToken();
      }
    }
  }

  void _startConversationSync() {
    _conversationSyncTimer?.cancel();
    unawaited(_sendPresenceHeartbeatSafely());
    _conversationSyncTimer = Timer.periodic(const Duration(seconds: 15), (
      _,
    ) async {
      try {
        await _sendPresenceHeartbeatSafely();
        await _loadRemoteConversations();
      } on AirTextApiException catch (error) {
        if (error.statusCode == 401) {
          _conversationSyncTimer?.cancel();
          await _api.clearToken();
        }
      }
    });
  }

  Future<void> _sendPresenceHeartbeatSafely() async {
    try {
      await _api.sendPresenceHeartbeat();
    } on AirTextApiException {
      debugPrint('Presence heartbeat unavailable.');
    }
  }

  Future<void> _startCallSignaling(int userId) async {
    await _stopCallSignaling();
    await _startPushNotifications();

    final token = _api.accessToken;
    if (token == null || _reverbKey.isEmpty) return;

    final client = AirTextCallClient(
      apiBaseUri: _api.apiBaseUri,
      token: token,
      reverbHost: _reverbHost,
      reverbKey: _reverbKey,
      reverbPort: _reverbPort,
      useTls: _reverbUseTls,
    );
    _callClient = client;
    _callSignalSubscription = client.signals.listen((signal) {
      if (signal.kind == 'incoming') {
        unawaited(
          _showIncomingCall(
            signal.callId,
            signal.payload['caller_name'] as String? ?? 'AirText contact',
          ),
        );
      }
    });
    _messageUpdateSubscription = client.messageUpdates.listen((_) {
      unawaited(_refreshConversationsFromRealtime());
    });

    try {
      await client.connect(userId);
      final response = await client.getActiveCall();
      final activeCall = response['data'];
      if (activeCall is Map<String, dynamic>) {
        unawaited(
          _showIncomingCall(
            activeCall['id'] as String,
            activeCall['caller_name'] as String? ?? 'AirText contact',
          ),
        );
      }
    } catch (_) {
      await _callSignalSubscription?.cancel();
      _callSignalSubscription = null;
      await _messageUpdateSubscription?.cancel();
      _messageUpdateSubscription = null;
      await client.dispose();
      if (identical(_callClient, client)) _callClient = null;
    }
  }

  Future<void> _startPushNotifications() async {
    if (_pushSetupComplete) return;
    final options = airTextFirebaseOptions;
    if (options == null) return;

    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (_) {
          if (!mounted) return;
          setState(() => _selectedTab = 0);
          unawaited(_refreshConversationsFromRealtime());
        },
      );
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) await _registerPushToken(token);
      _pushTokenSubscription = messaging.onTokenRefresh.listen(
        (token) => unawaited(_registerPushToken(token)),
      );
      _pushOpenSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => unawaited(_recoverCallFromPush(message)),
      );
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
        (message) => unawaited(_showForegroundMessage(message)),
      );
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        unawaited(_recoverCallFromPush(initialMessage));
      }
      _pushSetupComplete = true;
    } catch (_) {
      _pushSetupComplete = false;
    }
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    if (message.data['type'] != 'message') return;
    final title = message.notification?.title ?? 'New AirText message';
    final body = message.notification?.body ?? 'You received a new message.';
    final tone = await NotificationSoundService.getMessageTone();
    final soundName = switch (tone) {
      'Modern ping' => 'airtext_modern_ping',
      'Soft echo' => 'airtext_soft_echo',
      _ => 'airtext_chime',
    };

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'airtext_foreground_messages',
          'Messages',
          channelDescription: 'Notifications for incoming AirText messages',
          importance: Importance.high,
          priority: Priority.high,
          playSound: await NotificationSoundService.isMessageSoundEnabled(),
          sound: RawResourceAndroidNotificationSound(soundName),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: await NotificationSoundService.isMessageSoundEnabled(),
        ),
      ),
      payload: message.data['conversation_id'] as String?,
    );
  }

  Future<void> _registerPushToken(String token) async {
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
    if (platform == null || !_api.isAuthenticated) return;
    try {
      await _api.registerPushToken(
        token,
        platform,
        messageTone: await NotificationSoundService.getMessageTone(),
      );
    } on AirTextApiException {
      // Push registration is optional until a Firebase project is configured.
    }
  }

  Future<void> _stopPushNotifications() async {
    await _pushTokenSubscription?.cancel();
    _pushTokenSubscription = null;
    await _pushOpenSubscription?.cancel();
    _pushOpenSubscription = null;
    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    _pushSetupComplete = false;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && _api.isAuthenticated) {
        await _api.removePushToken(token);
      }
    } catch (_) {
      // Firebase is optional until a project is configured for this build.
    }
  }

  Future<void> _recoverCallFromPush(RemoteMessage message) async {
    if (message.data['type'] == 'message') {
      await _refreshConversationsFromRealtime();
      return;
    }
    if (message.data['type'] != 'direct_call') return;
    final callId = message.data['call_id'] as String?;
    final client = _callClient;
    if (callId == null || client == null) return;

    try {
      final response = await client.getActiveCall();
      final call = response['data'];
      if (call is Map<String, dynamic> && call['id'] == callId) {
        await _showIncomingCall(
          callId,
          call['caller_name'] as String? ?? 'AirText contact',
        );
      }
    } on AirTextCallClientException {
      // The active-call sync will retry when the Reverb connection is ready.
    }
  }

  Future<void> _stopCallSignaling() async {
    _incomingCallDialogId = null;
    await _callSignalSubscription?.cancel();
    _callSignalSubscription = null;
    await _messageUpdateSubscription?.cancel();
    _messageUpdateSubscription = null;
    final client = _callClient;
    _callClient = null;
    await client?.dispose();
  }

  Future<void> _showIncomingCall(String callId, String callerName) async {
    if (!mounted || _incomingCallDialogId == callId) return;
    _incomingCallDialogId = callId;
    unawaited(NotificationSoundService.startCallSound());

    final answer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Incoming AirText video call'),
        content: Text('$callerName is calling.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Decline'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.video_call_rounded),
            label: const Text('Answer'),
          ),
        ],
      ),
    );
    await NotificationSoundService.stopCallSound();
    _incomingCallDialogId = null;
    if (!mounted) return;

    final client = _callClient;
    if (client == null) return;

    try {
      if (answer == true) {
        await client.acceptCall(callId);
        if (!mounted) return;
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ActiveVideoCallScreen(
              callClient: client,
              callId: callId,
              contactName: callerName,
              isCaller: false,
              startMuted: false,
              startCameraOff: false,
            ),
          ),
        );
      } else if (answer == false) {
        await client.declineCall(callId);
      }
    } on AirTextCallClientException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _onApiAuthenticated(Map<String, dynamic> user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('airtext.account', jsonEncode(user));
    await preferences.remove('airtext.signed-out');
    try {
      await _loadRemoteConversations();
    } on AirTextApiException catch (error) {
      if (error.statusCode == 401) {
        await _api.clearToken();
        rethrow;
      }
    }
    if (!mounted) return;
    setState(() {
      _signedOutLocked = false;
      _sessionRestored = true;
      _displayName = user['name'] as String? ?? _displayName;
      _username = user['email'] as String? ?? _username;
    });
    _startConversationSync();
    await _startCallSignaling(user['id'] as int);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.appearance.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_sessionRestored) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_signedOutLocked) {
      return Scaffold(
        body: WelcomeScreen(
          language: widget.appearance.language,
          onChooseLanguage: () => unawaited(_chooseAppLanguage()),
          continueLabel: 'Sign in or create account',
          onContinue: () => unawaited(_openAccount()),
        ),
      );
    }
    if (_appLocked) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 42),
                const SizedBox(height: 14),
                const Text('Air app is locked'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => unawaited(_authenticateAppLock()),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock with biometrics'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _chatLocked && widget.appearance.chatLockEnabled
                ? Center(
                    child: FilledButton.icon(
                      onPressed: () => unawaited(_authenticateChatLock()),
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock chats'),
                    ),
                  )
                : _buildChats(),
            _UpdatesPage(api: _api, displayName: _displayName),
            const _AirTextShopPage(),
            _SettingsPage(
              api: _api,
              appearance: widget.appearance,
              onOpenProfile: () => setState(() => _selectedTab = 4),
              onOpenAccount: _openAccount,
              onOpenAppearance: _openAppearance,
            ),
            _ProfilePage(
              displayName: _displayName,
              username: _username,
              about: _about,
              imageBytes: _profileImage,
              imageUrl: _profilePhotoUrl,
              onSave: _saveProfile,
              onOpenAccount: _openAccount,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _FloatingNavigationDock(
        selectedIndex: _selectedTab,
        onSelected: (index) async {
          if (index == 0 && widget.appearance.chatLockEnabled && _chatLocked) {
            if (!await _authenticateChatLock()) return;
          }
          if (!mounted) return;
          setState(() {
            if (index != 0 && widget.appearance.chatLockEnabled) {
              _chatLocked = true;
            }
            _selectedTab = index;
          });
        },
      ),
    );
  }

  Widget _buildChats() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? _nexusBackground : _paper;
    final panel = isDark ? _nexusPanel : _lightPanel;
    final border = isDark ? _nexusBorder : _lightBorder;
    final textColor = isDark ? _nexusText : _ink;
    final mutedColor = isDark ? _nexusMuted : _lightMuted;
    final accentColor = isDark ? _nexusAccent : _green;
    final query = _searchController.text.trim().toLowerCase();
    final visibleConversations = _conversations.where((conversation) {
      final matchesSearch = conversation.name.toLowerCase().contains(query);
      final matchesFilter = _filter == 'All' || conversation.unread > 0;
      return matchesSearch && matchesFilter;
    }).toList();

    return Container(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _appCopy(context, 'Chats'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _appCopy(context, 'New conversation'),
                  onPressed: _startNewConversation,
                  icon: Icon(Icons.add, color: mutedColor),
                ),
                IconButton(
                  tooltip: _commandExpanded
                      ? _appCopy(context, 'Close command sphere')
                      : _appCopy(context, 'Open command sphere'),
                  onPressed: () =>
                      setState(() => _commandExpanded = !_commandExpanded),
                  icon: Icon(
                    _commandExpanded ? Icons.close_rounded : Icons.hub_outlined,
                    color: mutedColor,
                  ),
                ),
                IconButton(
                  tooltip: _appCopy(context, 'More options'),
                  onPressed: _showChatActions,
                  icon: Icon(CupertinoIcons.ellipsis, color: mutedColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: _appCopy(context, 'Search or start a new chat'),
                hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: mutedColor, size: 20),
                filled: true,
                fillColor: panel,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: accentColor),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: _commandExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        _NexusAction(
                          icon: Icons.edit_square,
                          label: _appCopy(context, 'New message'),
                          onTap: _startNewConversation,
                        ),
                        const SizedBox(width: 8),
                        _NexusAction(
                          icon: CupertinoIcons.person_2,
                          label: _appCopy(context, 'Contacts'),
                          onTap: _openContacts,
                        ),
                        const SizedBox(width: 8),
                        _NexusAction(
                          icon: CupertinoIcons.phone,
                          label: _appCopy(context, 'Calls'),
                          onTap: _openCalls,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final filter in const ['All', 'Unread'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_appCopy(context, filter)),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: panel,
                      selectedColor: isDark
                          ? const Color(0xFF26372F)
                          : const Color(0xFFD9EEE5),
                      side: BorderSide(
                        color: _filter == filter ? accentColor : border,
                      ),
                      labelStyle: TextStyle(
                        color: _filter == filter ? accentColor : mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  '${visibleConversations.length}',
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleConversations.isEmpty
                ? Center(
                    child: Text(
                      _appCopy(context, 'No chats found'),
                      style: TextStyle(color: mutedColor),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    itemCount: visibleConversations.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, indent: 76, color: border),
                    itemBuilder: (context, index) => _ConversationTile(
                      conversation: visibleConversations[index],
                      onTap: () =>
                          _openConversation(visibleConversations[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openConversation(ChatConversation conversation) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ChatDetailPage(
          conversation: conversation,
          api: _api,
          appearance: widget.appearance,
          displayName: _displayName,
          callClient: _callClient,
          onMessageSent: () => setState(() {}),
        ),
      ),
    );
  }

  Future<void> _openAppearance() async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => _AppearancePage(
          appearance: widget.appearance,
          onOpenChatTheme: () => _openChatTheme(),
        ),
      ),
    );
  }

  Future<void> _openChatTheme() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => _ChatThemePage(appearance: widget.appearance),
      ),
    );
  }

  Future<void> _startNewConversation() async {
    if (!_api.isAuthenticated) {
      await _openAccount();
      return;
    }

    final details = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _NewConversationDialog(),
    );
    if (details == null || !mounted) return;

    final email = details['email']!;
    final phone = details['phone']!;
    if (email.isEmpty == phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter one email address or phone number.'),
        ),
      );
      return;
    }

    try {
      final conversation = await _api.createConversation(
        email: email.isEmpty ? null : email,
        phoneNumber: phone.isEmpty ? null : phone,
        name: details['name']!.isEmpty ? null : details['name'],
      );
      if (!mounted) return;
      setState(() {
        _conversations.removeWhere(
          (item) => item.backendId == conversation.backendId,
        );
        _conversations.insert(0, conversation);
      });
      _openConversation(conversation);
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _loadSavedContacts() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('airtext.contacts');
    if (saved == null || !mounted) return;

    final contacts = (jsonDecode(saved) as List<dynamic>)
        .map((item) => AirTextContact.fromJson(item as Map<String, dynamic>))
        .toList();
    setState(() => _contacts = contacts);
  }

  Future<void> _loadSavedProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('airtext.profile');
    if (saved == null || !mounted) return;
    final profile = jsonDecode(saved) as Map<String, dynamic>;
    setState(() {
      _displayName = profile['displayName'] as String? ?? _displayName;
      _username = profile['username'] as String? ?? _username;
      _about = profile['about'] as String? ?? _about;
      final image = profile['image'] as String?;
      _profileImage = image == null ? null : base64Decode(image);
    });
  }

  Future<void> _saveProfile(
    String displayName,
    String username,
    String about,
    Uint8List? imageBytes,
  ) async {
    if (_api.isAuthenticated) {
      try {
        await _api.updateProfile(displayName);
      } on AirTextApiException catch (error) {
        if (error.statusCode != 403) rethrow;
      }
      if (imageBytes != null) await _api.updateProfilePhoto(imageBytes);
    }
    setState(() {
      _displayName = displayName;
      _username = username;
      _about = about;
      _profileImage = imageBytes;
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'airtext.profile',
      jsonEncode({
        'displayName': displayName,
        'username': username,
        'about': about,
        'image': imageBytes == null ? null : base64Encode(imageBytes),
      }),
    );
  }

  Future<void> _openAccount() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => _AccountPage(
          api: _api,
          appearance: widget.appearance,
          onAuthenticated: _onApiAuthenticated,
          onSaveProfile: (name, email, imageBytes) =>
              _saveProfile(name, email, _about, imageBytes),
          onSignOut: _signOutLocally,
          onDeleteLocalData: _deleteLocalData,
          onDeleteAccount: _deleteAccount,
        ),
      ),
    );
  }

  Future<void> _chooseAppLanguage() async {
    final selected = await Navigator.of(context).push<String>(
      CupertinoPageRoute<String>(
        builder: (_) => LanguageSelectorScreen(api: _api),
      ),
    );
    if (selected != null && selected.isNotEmpty) {
      await widget.appearance.setLanguage(selected);
    }
  }

  Future<void> _signOutLocally() async {
    await _stopPushNotifications();
    try {
      await _api.logout();
    } on AirTextApiException {
      await _api.clearToken();
    }
    _conversationSyncTimer?.cancel();
    await _stopCallSignaling();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('airtext.signed-out', true);
    if (!mounted) return;
    setState(() {
      _signedOutLocked = true;
      _sessionRestored = true;
      _selectedTab = 0;
      _conversations
        ..clear()
        ..addAll(_offlineConversations);
    });
    Navigator.of(context).pop();
  }

  Future<void> _deleteLocalData() async {
    await _stopPushNotifications();
    try {
      await _api.logout();
    } on AirTextApiException {
      await _api.clearToken();
    }
    _conversationSyncTimer?.cancel();
    await _stopCallSignaling();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('airtext.profile');
    await preferences.remove('airtext.account');
    await preferences.remove('airtext.contacts');
    await preferences.setBool('airtext.signed-out', true);
    if (!mounted) return;
    setState(() {
      _signedOutLocked = true;
      _sessionRestored = true;
      _contacts = [];
      _displayName = 'Air app User';
      _username = '@airapp';
      _about = 'Available';
      _profileImage = null;
      _selectedTab = 0;
      _conversations
        ..clear()
        ..addAll(_offlineConversations);
    });
    Navigator.of(context).pop();
  }

  Future<void> _deleteAccount() async {
    await _stopPushNotifications();
    try {
      await _api.deleteAccount();
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }

    _conversationSyncTimer?.cancel();
    await _stopCallSignaling();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('airtext.profile');
    await preferences.remove('airtext.account');
    await preferences.remove('airtext.contacts');
    await preferences.setBool('airtext.signed-out', true);
    if (!mounted) return;
    setState(() {
      _signedOutLocked = true;
      _sessionRestored = true;
      _contacts = [];
      _displayName = 'Air app User';
      _username = '@airapp';
      _about = 'Available';
      _profileImage = null;
      _selectedTab = 0;
      _conversations
        ..clear()
        ..addAll(_offlineConversations);
    });
    Navigator.of(context).pop();
  }

  Future<void> _saveContacts() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'airtext.contacts',
      jsonEncode(_contacts.map((contact) => contact.toJson()).toList()),
    );
  }

  Future<void> _openContacts() async {
    if (_api.isAuthenticated) {
      try {
        final remoteContacts = await _api.getContacts();
        if (!mounted) return;
        final contactsByNumber = {
          for (final contact in _contacts) contact.phoneNumber: contact,
          for (final contact in remoteContacts)
            contact.phoneNumber: contact,
        };
        setState(() => _contacts = contactsByNumber.values.toList());
        await _saveContacts();
      } on AirTextApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load synced contacts: ${error.message}')),
        );
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => _ContactsPage(
          api: _api,
          contacts: _contacts,
          onContactSaved: (contact) {
            setState(() => _contacts = [..._contacts, contact]);
            _saveContacts();
          },
          onOpenChat: (contact) => unawaited(_openContactChat(contact)),
        ),
      ),
    );
  }

  Future<void> _openContactChat(AirTextContact contact) async {
    final existing = _conversations
        .cast<ChatConversation?>()
        .firstWhere(
          (conversation) => conversation?.phoneNumber == contact.phoneNumber,
          orElse: () => null,
        );
    var conversation = existing;
    if (_api.isAuthenticated && existing?.backendId == null) {
      try {
        conversation = await _api.createConversation(
          phoneNumber: contact.phoneNumber,
          name: contact.name,
        );
      } on AirTextApiException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start chat: ${error.message}')),
          );
        }
        return;
      }
    }
    conversation ??= ChatConversation(
      name: contact.name,
      initials: contact.initials,
      status: contact.isAirTextUser ? 'Air app contact' : 'SMS contact',
      time: 'New',
      unread: 0,
      color: const Color(0xFFDCE8F8),
      phoneNumber: contact.phoneNumber,
                  payloadPrefix: contact.payloadPrefix,
      messages: [],
    );
    if (existing == null) _conversations.add(conversation);
    if (!mounted) return;
    Navigator.of(context).pop();
    _openConversation(conversation);
  }

  Future<void> _openCalls() async {
    await Navigator.of(context)
        .push<void>(CupertinoPageRoute<void>(builder: (_) => _CallsPage()));
  }

  Future<void> _showChatActions() async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'link'),
            child: const Text('Link a device'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'group'),
            child: const Text('New group'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'broadcast'),
            child: const Text('Broadcast list'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'read'),
            child: const Text('Mark all as read'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'settings'),
            child: const Text('Settings'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'link':
        await Navigator.of(context).push<void>(
          CupertinoPageRoute<void>(builder: (_) => const _LinkDevicePage()),
        );
      case 'group':
        final group = await Navigator.of(context).push<_GroupDraft>(
          CupertinoPageRoute<_GroupDraft>(
            builder: (_) => _NewGroupPage(contacts: _contacts),
          ),
        );
        if (group == null || !mounted) return;
        final conversation = ChatConversation(
          name: group.name,
          initials: group.initials,
          status: 'Group · ${group.contacts.length} members',
          time: 'New',
          unread: 0,
          color: const Color(0xFFE5EFFF),
          messages: [],
        );
        setState(() => _conversations.add(conversation));
        _openConversation(conversation);
      case 'broadcast':
        await Navigator.of(context).push<void>(
          CupertinoPageRoute<void>(
            builder: (_) => _BroadcastListPage(contacts: _contacts),
          ),
        );
      case 'read':
        setState(() {
          for (final conversation in _conversations) {
            conversation.unread = 0;
          }
        });
      case 'settings':
        setState(() => _selectedTab = 3);
    }
  }
}

class _GroupDraft {
  const _GroupDraft(this.name, this.contacts);

  final String name;
  final List<AirTextContact> contacts;
  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

class _NewGroupPage extends StatefulWidget {
  const _NewGroupPage({required this.contacts});

  final List<AirTextContact> contacts;

  @override
  State<_NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<_NewGroupPage> {
  final _nameController = TextEditingController();
  final Set<AirTextContact> _selectedContacts = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('New group'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoTextField(
              controller: _nameController,
              placeholder: 'Group name',
              padding: const EdgeInsets.all(13),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _ListSectionLabel('ADD PARTICIPANTS'),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final contact in widget.contacts)
                  CheckboxListTile.adaptive(
                    value: _selectedContacts.contains(contact),
                    activeColor: _green,
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                    onChanged: (selected) => setState(() {
                      if (selected == true) {
                        _selectedContacts.add(contact);
                      } else {
                        _selectedContacts.remove(contact);
                      }
                    }),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedContacts.isEmpty ? null : _create,
                  child: Text('Create group (${_selectedContacts.length})'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _create() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a group name.')));
      return;
    }
    Navigator.pop(context, _GroupDraft(name, _selectedContacts.toList()));
  }
}

class _BroadcastListPage extends StatefulWidget {
  const _BroadcastListPage({required this.contacts});

  final List<AirTextContact> contacts;

  @override
  State<_BroadcastListPage> createState() => _BroadcastListPageState();
}

class _BroadcastListPageState extends State<_BroadcastListPage> {
  final Set<AirTextContact> _selectedContacts = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Broadcast list'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Text(
              'Choose saved contacts for a local broadcast list. Sending to multiple recipients requires an SMS service.',
              style: TextStyle(color: Color(0xFF6D6D72), fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final contact in widget.contacts)
                  CheckboxListTile.adaptive(
                    value: _selectedContacts.contains(contact),
                    activeColor: _green,
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                    onChanged: (selected) => setState(() {
                      if (selected == true) {
                        _selectedContacts.add(contact);
                      } else {
                        _selectedContacts.remove(contact);
                      }
                    }),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedContacts.isEmpty
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Broadcast list saved for ${_selectedContacts.length} contacts on this device.',
                            ),
                          ),
                        ),
                  child: Text('Save list (${_selectedContacts.length})'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkDevicePage extends StatelessWidget {
  const _LinkDevicePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Link a device'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.device_phone_portrait,
                size: 54,
                color: _green,
              ),
              const SizedBox(height: 18),
              const Text(
                'Device linking needs an authenticated Air app account service.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A secure one-time pairing code will appear here once that service is connected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6D6D72), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewConversationDialog extends StatefulWidget {
  const _NewConversationDialog();

  @override
  State<_NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<_NewConversationDialog> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New conversation'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Air app account email',
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('or'),
          ),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'SMS number (+country code)',
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Contact name (optional)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, {
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'name': _nameController.text.trim(),
        }),
        child: const Text('Create'),
      ),
    ],
  );
}

class AirTextContact {
  const AirTextContact({
    required this.name,
    required this.phoneNumber,
    required this.isAirTextUser,
    this.payloadPrefix = 'MSG:',
    this.backendId,
  });

  final String name;
  final String phoneNumber;
  final bool isAirTextUser;
  final String payloadPrefix;
  final int? backendId;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  Map<String, dynamic> toJson() => {
    'name': name,
    'phoneNumber': phoneNumber,
    'isAirTextUser': isAirTextUser,
    'payloadPrefix': payloadPrefix,
    'backendId': backendId,
  };

  factory AirTextContact.fromJson(Map<String, dynamic> json) => AirTextContact(
    name: json['name'] as String,
    phoneNumber: json['phoneNumber'] as String,
    isAirTextUser: json['isAirTextUser'] as bool? ?? false,
    payloadPrefix: json['payloadPrefix'] as String? ?? 'MSG:',
    backendId: json['backendId'] as int?,
  );

  factory AirTextContact.fromApi(Map<String, dynamic> json) => AirTextContact(
    name: json['name'] as String,
    phoneNumber: json['phone_number'] as String,
    isAirTextUser: json['is_registered'] as bool? ?? false,
    payloadPrefix: json['payload_prefix'] as String? ?? 'MSG:',
    backendId: json['id'] as int?,
  );
}

class _ContactsPage extends StatefulWidget {
  const _ContactsPage({
    required this.api,
    required this.contacts,
    required this.onContactSaved,
    required this.onOpenChat,
  });

  final AirTextApi api;
  final List<AirTextContact> contacts;
  final ValueChanged<AirTextContact> onContactSaved;
  final ValueChanged<AirTextContact> onOpenChat;

  @override
  State<_ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<_ContactsPage> {
  final _searchController = TextEditingController();
  String _filter = 'All';
  bool _syncingPhoneContacts = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final contacts = widget.contacts.where((contact) {
      final matchesFilter = switch (_filter) {
        'Air app' => contact.isAirTextUser,
        'Invite' => !contact.isAirTextUser,
        _ => true,
      };
      return matchesFilter &&
          '${contact.name} ${contact.phoneNumber}'.toLowerCase().contains(
            query,
          );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Contacts'),
        actions: [
          IconButton(
            tooltip: 'Sync phone contacts',
            onPressed: _syncingPhoneContacts ? null : _syncPhoneContacts,
            icon: _syncingPhoneContacts
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CupertinoIcons.person_crop_circle_badge_checkmark),
          ),
          IconButton(
            tooltip: 'Add contact',
            onPressed: _addContact,
            icon: const Icon(CupertinoIcons.person_add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Search contacts',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoSlidingSegmentedControl<String>(
              groupValue: _filter,
              children: const {
                'All': Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('All'),
                ),
                'Air app': Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Air app'),
                ),
                'Invite': Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Invite'),
                ),
              },
              onValueChanged: (value) {
                if (value != null) setState(() => _filter = value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: contacts.isEmpty
                ? const Center(child: Text('No contacts found'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                    itemCount: contacts.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 72,
                      color: Color(0xFFE8ECE7),
                    ),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE5EFFF),
                          foregroundColor: const Color(0xFF245781),
                          child: Text(contact.initials),
                        ),
                        title: Text(
                          contact.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(contact.phoneNumber),
                        trailing: contact.isAirTextUser
                            ? IconButton(
                                tooltip: 'Message',
                                onPressed: () => widget.onOpenChat(contact),
                                icon: const Icon(
                                  CupertinoIcons.chat_bubble_text,
                                  color: _green,
                                ),
                              )
                            : TextButton.icon(
                                onPressed: () => _invite(contact),
                                icon: const Icon(
                                  CupertinoIcons.paperplane,
                                  size: 16,
                                ),
                                label: const Text('Invite'),
                              ),
                        onTap: contact.isAirTextUser
                            ? () => widget.onOpenChat(contact)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Add contact',
        onPressed: _addContact,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        child: const Icon(CupertinoIcons.person_add),
      ),
    );
  }

  Future<void> _syncPhoneContacts() async {
    if (!widget.api.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to sync phone contacts.')),
      );
      return;
    }

    setState(() => _syncingPhoneContacts = true);
    try {
      final permission = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.limited) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact access was not allowed.')),
          );
        }
        return;
      }

      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      final phoneNumbers = <String>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final number = _toE164(phone.normalizedNumber ?? phone.number);
          if (number != null) phoneNumbers.add(number);
        }
      }
      if (contacts.isNotEmpty && phoneNumbers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No international phone numbers found; existing synced contacts were kept.',
              ),
            ),
          );
        }
        return;
      }

      final matched = await widget.api.syncPhoneContacts(phoneNumbers.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$matched AirText contacts synced.')),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not sync contacts: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncingPhoneContacts = false);
    }
  }

  String? _toE164(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s().-]'), '');
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalized)
        ? normalized
        : null;
  }

  Future<void> _addContact() async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _NewContactDialog(),
    );
    if (values == null || !mounted) return;

    final contactName = [values['first_name'], values['last_name']]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
    var contact = AirTextContact(
      name: contactName,
      phoneNumber: values['phone']!,
      isAirTextUser: false,
      payloadPrefix: values['payload_prefix']!,
    );
    if (widget.api.isAuthenticated) {
      try {
        contact = await widget.api.createContact(
          name: contactName,
          phoneNumber: contact.phoneNumber,
          payloadPrefix: contact.payloadPrefix,
        );
      } on AirTextApiException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save contact: ${error.message}')),
        );
        return;
      }
    }
    if (!mounted) return;
    widget.onContactSaved(contact);
  }

  Future<void> _invite(AirTextContact contact) async {
    final uri = Uri(
      scheme: 'sms',
      path: contact.phoneNumber.replaceAll(RegExp(r'\s+'), ''),
      queryParameters: {'body': 'Join me on Air app.'},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No SMS app is available on this device.'),
        ),
      );
    }
  }
}

class _NewContactDialog extends StatefulWidget {
  const _NewContactDialog();

  @override
  State<_NewContactDialog> createState() => _NewContactDialogState();
}

class _NewContactDialogState extends State<_NewContactDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _payloadPrefix = 'MSG:';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New contact'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _firstNameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'First name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a first name'
                : null,
          ),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(labelText: 'Last name'),
          ),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'GSM phone number',
              hintText: '+255712884102',
            ),
            validator: (value) => value == null ||
                    !RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(
                      value.replaceAll(RegExp(r'[\s().-]'), ''),
                    )
                ? 'Use an international number, e.g. +255712884102'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _payloadPrefix,
            decoration: const InputDecoration(
              labelText: 'Default payload prefix',
            ),
            items: const [
              DropdownMenuItem(value: 'MSG:', child: Text('MSG:')),
              DropdownMenuItem(value: 'STAT:', child: Text('STAT:')),
              DropdownMenuItem(value: 'ACK:', child: Text('ACK:')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _payloadPrefix = value);
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'phone': _phoneController.text
                .trim()
                .replaceAll(RegExp(r'[\s().-]'), ''),
            'payload_prefix': _payloadPrefix,
          });
        },
        child: const Text('Save contact'),
      ),
    ],
  );
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAirTextRoute = !conversation.isSmsRoute;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : _ink;
    final mutedColor = isDark ? _silver : _lightMuted;
    final routeAccent = isAirTextRoute
        ? (isDark ? _mint : _green)
        : (isDark ? const Color(0xFFD9B77A) : const Color(0xFF805A18));
    final lastMessage = conversation.messages.isEmpty
        ? null
        : conversation.messages.last;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? _panelRaised : _lightPanelRaised,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  conversation.initials,
                  style: TextStyle(
                    color: isDark ? _nexusText : _green,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conversation.time,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (lastMessage?.isMine ?? false) ...[
                          Icon(Icons.done_all, size: 16, color: routeAccent),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            lastMessage?.text ?? conversation.status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: mutedColor, fontSize: 12),
                          ),
                        ),
                        if (conversation.unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            height: 20,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: isDark ? _mint : _green,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${conversation.unread}',
                              style: TextStyle(
                                color: isDark ? _obsidian : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NexusAction extends StatelessWidget {
  const _NexusAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: label,
      child: Material(
        color: isDark ? _panel : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 19,
              color: isDark ? _silver : const Color(0xFF53635B),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    required this.conversation,
    required this.api,
    required this.appearance,
    required this.displayName,
    required this.callClient,
    required this.onMessageSent,
    super.key,
  });

  final ChatConversation conversation;
  final AirTextApi api;
  final AirTextAppearance appearance;
  final String displayName;
  final AirTextCallClient? callClient;
  final VoidCallback onMessageSent;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _messageController = TextEditingController();
  final AudioRecorder _voiceRecorder = AudioRecorder();
  Timer? _expiryTimer;
  Timer? _syncTimer;
  Timer? _typingTimer;
  Timer? _typingLeaseTimer;
  bool _showEmojiPicker = false;
  bool _viewOnceMessage = false;
  bool _smsFallbackEnabled = true;
  bool _globalReadReceipts = true;
  bool _isRecordingVoice = false;
  String? _voiceRecordingPath;
  String? _counterpartActivity;
  late String _disappearingDuration;
  late bool _blocked;
  late bool _reported;
  late bool _shareLastSeen;
  late bool _readReceipts;

  @override
  void initState() {
    super.initState();
    unawaited(_setScreenPrivacy(true));
    _disappearingDuration = widget.conversation.disappearingDuration;
    _blocked = widget.conversation.isBlocked;
    _reported = widget.conversation.isReported;
    _shareLastSeen = widget.conversation.shareLastSeen;
    _readReceipts = widget.conversation.readReceipts;
    unawaited(_loadSmsFallbackPreference());
    _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final messageCount = widget.conversation.messages.length;
      widget.conversation.messages.removeWhere(
        (message) => message.expiresAt?.isBefore(DateTime.now()) ?? false,
      );
      if (widget.conversation.messages.length != messageCount && mounted) {
        setState(() {});
        widget.onMessageSent();
      }
    });
    if (widget.api.isAuthenticated && widget.conversation.backendId != null) {
      _syncTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _syncRemoteConversation(),
      );
      _typingTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _pollTypingActivity(),
      );
    }
  }

  Future<void> _loadSmsFallbackPreference() async {
    final prefs = await SharedPreferences.getInstance();
    var enabled = prefs.getBool('sms_fallback_enabled') ?? true;
    var readReceiptsEnabled = prefs.getBool('sms_delivery_receipts') ?? true;
    if (widget.api.isAuthenticated) {
      try {
        final preferences = await widget.api.getUserPreferences();
        final messaging = preferences['messaging_settings'];
        if (messaging is Map<String, dynamic>) {
          enabled = messaging['sms_fallback_enabled'] as bool? ?? enabled;
          readReceiptsEnabled =
              messaging['delivery_receipts'] as bool? ?? readReceiptsEnabled;
        }
      } on AirTextApiException {
        // Use the last saved device preferences while offline.
      }
    }
    if (!mounted) return;
    setState(() {
      _smsFallbackEnabled = enabled;
      _globalReadReceipts = readReceiptsEnabled;
    });
    if (readReceiptsEnabled && widget.api.isAuthenticated) {
      await _markConversationRead();
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _syncTimer?.cancel();
    _typingTimer?.cancel();
    _typingLeaseTimer?.cancel();
    if (_isRecordingVoice) unawaited(_voiceRecorder.cancel());
    unawaited(_voiceRecorder.dispose());
    unawaited(_setScreenPrivacy(false));
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markConversationRead() async {
    final backendId = widget.conversation.backendId;
    if (backendId == null || !_readReceipts || !_globalReadReceipts) return;

    try {
      await widget.api.markConversationRead(backendId);
      if (!mounted) return;
      setState(() {
        widget.conversation.unread = 0;
        for (final message in widget.conversation.messages) {
          if (!message.isMine && message.status != 'failed') {
            message.status = 'read';
          }
        }
      });
      widget.onMessageSent();
    } on AirTextApiException catch (error) {
      if (error.statusCode == 401) await widget.api.clearToken();
    }
  }

  void _onComposerChanged(String value) {
    setState(() {});
    if (value.trim().isEmpty) {
      unawaited(_publishConversationActivity(false));
      return;
    }
    unawaited(_publishConversationActivity(true));
  }

  Future<void> _publishConversationActivity(
    bool active, {
    String activity = 'typing',
  }) async {
    final conversationId = widget.conversation.backendId;
    if (conversationId == null || !widget.api.isAuthenticated) return;
    _typingLeaseTimer?.cancel();
    try {
      await widget.api.setTyping(conversationId, active, activity: activity);
    } on AirTextApiException {
      return;
    }
    if (active) {
      _typingLeaseTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        unawaited(_publishConversationActivity(true, activity: activity));
      });
    }
  }

  Future<void> _pollTypingActivity() async {
    final conversationId = widget.conversation.backendId;
    if (conversationId == null || !widget.api.isAuthenticated) return;
    try {
      final activity = await widget.api.getTypingStatus(conversationId);
      if (!mounted || activity == _counterpartActivity) return;
      setState(() => _counterpartActivity = activity);
    } on AirTextApiException {
      debugPrint('Typing activity poll failed.');
    }
  }

  Future<void> _toggleVoiceRecording() async {
    final conversationId = widget.conversation.backendId;
    if (!widget.api.isAuthenticated || conversationId == null) {
      await _showUnavailableFeature(
        'Voice messages',
        'Sign in to send voice messages in Air app chats.',
      );
      return;
    }
    if (widget.conversation.isSmsRoute) {
      await _showUnavailableFeature(
        'Voice messages',
        'Voice messages are available only in Air app conversations.',
      );
      return;
    }

    if (!_isRecordingVoice) {
      if (!await _voiceRecorder.hasPermission()) return;
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/airtext-${DateTime.now().microsecondsSinceEpoch}.wav';
      try {
        await _voiceRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );
        _voiceRecordingPath = path;
        if (!mounted) return;
        setState(() => _isRecordingVoice = true);
        await _publishConversationActivity(true, activity: 'recording');
      } on PlatformException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message ?? 'Could not start recording.'),
            ),
          );
        }
      }
      return;
    }

    final path = await _voiceRecorder.stop() ?? _voiceRecordingPath;
    _voiceRecordingPath = null;
    if (mounted) setState(() => _isRecordingVoice = false);
    await _publishConversationActivity(false);
    if (path == null || !File(path).existsSync()) return;
    try {
      final message = await widget.api.sendVoiceMessage(
        conversationId,
        path,
        viewOnce: _viewOnceMessage,
      );
      if (!mounted) return;
      setState(() {
        widget.conversation.messages.add(message);
        _viewOnceMessage = false;
      });
      widget.onMessageSent();
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      try {
        await File(path).delete();
      } on FileSystemException {
        debugPrint('Temporary voice cleanup failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAirTextRoute = conversation.status == 'Air app contact';
    final canvasColor = isDark
      ? const Color(0xFF0B141A)
      : const Color(0xFFEFEAE2);
    final panelColor = isDark
      ? const Color(0xFF202C33)
        : const Color(0xFFFFFFFF);
    final borderColor = isDark
      ? const Color(0xFF2B3A42)
      : const Color(0xFFE9EDEF);
    final primaryText = isDark ? const Color(0xFFF5F7FA) : _ink;
    final mutedText = isDark ? const Color(0xFF8D9EAF) : _lightMuted;
    final routeColor = isAirTextRoute
        ? widget.appearance.chatAccent
        : (isDark ? const Color(0xFFD9B77A) : const Color(0xFF805A18));
    return CupertinoPageScaffold(
      backgroundColor: canvasColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: canvasColor.withValues(alpha: 0.94),
        border: Border(bottom: BorderSide(color: borderColor)),
        leading: CupertinoNavigationBarBackButton(
          color: isDark ? _silver : _green,
        ),
        middle: GestureDetector(
          onTap: _openContactProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  conversation.initials,
                  style: TextStyle(color: mutedText),
                ),
              ),
              const SizedBox(width: 7),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _counterpartActivity == 'recording'
                        ? 'Recording audio…'
                        : _counterpartActivity == 'typing'
                        ? 'Typing…'
                        : conversation.status,
                    style: TextStyle(color: mutedText, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              minimumSize: Size.zero,
              onPressed: _startVideoCall,
              child: Icon(
                CupertinoIcons.video_camera,
                color: mutedText,
                size: 19,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              minimumSize: Size.zero,
              onPressed: () => _placeCall(conversation.phoneNumber),
              child: Icon(CupertinoIcons.phone, color: mutedText, size: 19),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              minimumSize: Size.zero,
              onPressed: _openContactProfile,
              child: Icon(CupertinoIcons.info, color: mutedText, size: 19),
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(left: 5),
              minimumSize: Size.zero,
              onPressed: _showChatActions,
              child: Icon(CupertinoIcons.ellipsis, color: mutedText, size: 19),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: panelColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: routeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.api.isAuthenticated
                        ? 'VAULT  ·  ACCOUNT SESSION'
                        : 'VAULT  ·  LOCAL PROFILE',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Text(
                  isAirTextRoute ? 'AIR APP' : 'SMS',
                  style: TextStyle(
                    color: routeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (_blocked)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'This contact is blocked',
                style: TextStyle(color: mutedText, fontSize: 12),
              ),
            ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: canvasColor,
                image: widget.appearance.chatWallpaper == null
                    ? null
                    : DecorationImage(
                        image: MemoryImage(widget.appearance.chatWallpaper!),
                        fit: BoxFit.cover,
                      ),
              ),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                itemCount: conversation.messages.length,
                itemBuilder: (context, index) {
                  final message = conversation.messages[index];
                  final previous = index == 0
                      ? null
                      : conversation.messages[index - 1].sentAt;
                  final sentAt = message.sentAt;
                  final showDate =
                      index == 0 ||
                      (sentAt != null &&
                          (previous == null ||
                              !_isSameChatDay(sentAt, previous)));
                  return Column(
                    children: [
                      if (showDate)
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: panelColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              sentAt == null
                                  ? 'Today'
                                  : _chatDateLabel(context, sentAt),
                              style: TextStyle(color: mutedText, fontSize: 11),
                            ),
                          ),
                        ),
                      _MessageBubble(
                        message: message,
                        api: widget.api,
                        conversationId: conversation.backendId,
                        isAirTextRoute: isAirTextRoute,
                        accentColor: widget.appearance.chatAccent,
                        onTranslate: () => _translateMessage(message),
                        onMessageChanged: widget.onMessageSent,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (_showEmojiPicker && !_blocked)
            SizedBox(
              key: const ValueKey('emoji-picker'),
              height: 260,
              child: EmojiPicker(
                textEditingController: _messageController,
                config: const Config(
                  height: 260,
                  checkPlatformCompatibility: false,
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                decoration: BoxDecoration(
                  color: panelColor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: 'Add emoji',
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size.zero,
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _showEmojiPicker = !_showEmojiPicker);
                        },
                        child: Icon(
                          Icons.emoji_emotions_outlined,
                          color: mutedText,
                          size: 21,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Add attachment',
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size.zero,
                        onPressed: _blocked ? null : _showAttachmentSheet,
                        child: Icon(
                          CupertinoIcons.add,
                          color: mutedText,
                          size: 22,
                        ),
                      ),
                    ),
                    if (isAirTextRoute)
                      Tooltip(
                        message: _viewOnceMessage
                            ? 'Turn off view once'
                            : 'Send view once',
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(7),
                          minimumSize: Size.zero,
                          onPressed: _blocked
                              ? null
                              : () => setState(
                                  () => _viewOnceMessage = !_viewOnceMessage,
                                ),
                          child: Icon(
                            CupertinoIcons.eye,
                            color: _viewOnceMessage
                                ? widget.appearance.chatAccent
                                : mutedText,
                            size: 20,
                          ),
                        ),
                      ),
                    Expanded(
                      child: CupertinoTextField(
                        controller: _messageController,
                        enabled: !_blocked,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        placeholder: _blocked
                            ? 'Unblock this contact to reply'
                            : 'Message',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        style: TextStyle(color: primaryText, fontSize: 16),
                        placeholderStyle: TextStyle(color: mutedText),
                        onChanged: _onComposerChanged,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: _messageController.text.trim().isEmpty
                          ? Tooltip(
                              message: _isRecordingVoice
                                  ? 'Stop and send voice message'
                                  : 'Record voice message',
                              child: CupertinoButton(
                                key: const ValueKey('voice'),
                                padding: const EdgeInsets.all(8),
                                minimumSize: Size.zero,
                                onPressed: _blocked
                                    ? null
                                    : _toggleVoiceRecording,
                                child: Icon(
                                  _isRecordingVoice
                                      ? CupertinoIcons.stop_circle_fill
                                      : CupertinoIcons.mic_fill,
                                  color: _isRecordingVoice
                                      ? const Color(0xFFCC3A3A)
                                      : widget.appearance.chatAccent,
                                  size: 21,
                                ),
                              ),
                            )
                          : Tooltip(
                              message: 'Send message',
                              child: CupertinoButton(
                                key: const ValueKey('send'),
                                padding: const EdgeInsets.all(7),
                                minimumSize: Size.zero,
                                color: widget.appearance.chatAccent,
                                borderRadius: BorderRadius.circular(22),
                                onPressed: _blocked ? null : _sendMessage,
                                child: const Icon(
                                  CupertinoIcons.arrow_up,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _translateMessage(ChatMessage message) async {
    final conversationId = widget.conversation.backendId;
    final messageId = message.backendId;
    if (!widget.api.isAuthenticated ||
        conversationId == null ||
        messageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only synced messages can be translated.'),
        ),
      );
      return;
    }

    try {
      final translation = await widget.api.translateMessage(
        conversationId: conversationId,
        messageId: messageId,
        targetLanguage: _languageCodeFor(widget.appearance.language),
      );
      if (!mounted) return;
      setState(() => message.translation = translation);
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _blocked) return;

    if (widget.conversation.isSmsRoute && _smsFallbackEnabled) {
      await _sendSmsThroughSim(text);
      return;
    }

    final backendId = widget.conversation.backendId;
    if (widget.api.isAuthenticated && backendId != null) {
      try {
        final message = await widget.api.sendMessage(
          backendId,
          text,
          viewOnce: _viewOnceMessage,
        );
        if (!mounted) return;
        setState(() {
          widget.conversation.messages.add(message);
          _messageController.clear();
          _showEmojiPicker = false;
          _viewOnceMessage = false;
        });
        await _publishConversationActivity(false);
        widget.onMessageSent();
      } on AirTextApiException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
        }
      }
      return;
    }

    final duration = switch (_disappearingDuration) {
      '24 hours' => const Duration(hours: 24),
      '7 days' => const Duration(days: 7),
      '90 days' => const Duration(days: 90),
      _ => null,
    };

    setState(() {
      widget.conversation.messages.add(
        ChatMessage(
          text,
          'Now',
          isMine: true,
          sentAt: DateTime.now(),
          expiresAt: duration == null ? null : DateTime.now().add(duration),
        ),
      );
      _messageController.clear();
    });
    setState(() => _showEmojiPicker = false);
    widget.onMessageSent();
  }

  Future<void> _sendSmsThroughSim(String text) async {
    final phoneNumber = widget.conversation.phoneNumber;
    if (phoneNumber.isEmpty) return;
    final prefix = widget.conversation.payloadPrefix;
    final smsBody = prefix == 'MSG:' ? text : '$prefix$text';

    try {
      final result = await SmsFallbackService.sendSms(
        phoneNumber: phoneNumber,
        message: smsBody,
      );
      if (result == SmsDispatchResult.composerOpened) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS draft opened. Confirm sending in your SMS app.'),
            ),
          );
        }
        return;
      }

      ChatMessage message = ChatMessage(
        text,
        _formatMessageTime(DateTime.now()),
        isMine: true,
        sentAt: DateTime.now(),
        status: 'sent',
      );
      final backendId = widget.conversation.backendId;
      if (widget.api.isAuthenticated && backendId != null) {
        try {
          message = await widget.api.recordLocalSms(
            conversationId: backendId,
            body: text,
            payloadPrefix: prefix,
          );
        } on AirTextApiException catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('SMS sent; chat history sync failed: ${error.message}')),
            );
          }
        }
      }
      if (!mounted) return;
      setState(() {
        widget.conversation.messages.add(message);
        _messageController.clear();
        _showEmojiPicker = false;
      });
      widget.onMessageSent();
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Could not send SMS through this SIM.')),
        );
      }
    }
  }

  Future<void> _syncRemoteConversation() async {
    final backendId = widget.conversation.backendId;
    if (backendId == null) return;
    try {
      final conversations = await widget.api.getConversations();
      final remote = conversations.cast<ChatConversation?>().firstWhere(
        (conversation) => conversation?.backendId == backendId,
        orElse: () => null,
      );
      if (remote == null || !mounted) return;
      setState(() {
        widget.conversation.status = remote.status;
        widget.conversation.isOnline = remote.isOnline;
        widget.conversation.lastSeenAt = remote.lastSeenAt;
        widget.conversation.messages
          ..clear()
          ..addAll(remote.messages);
      });
      widget.onMessageSent();
    } on AirTextApiException catch (error) {
      if (error.statusCode == 401) {
        _syncTimer?.cancel();
        await widget.api.clearToken();
      }
    }
  }

  Future<void> _placeCall(String number) async {
    if (number.trim().isEmpty) {
      await _showVideoUnavailable(
        title: 'No phone number',
        message: 'Add a phone number to this contact before calling.',
      );
      return;
    }
    await _openVoiceCallScreen(
      context,
      number,
      contactName: widget.conversation.name,
    );
  }

  Future<void> _startVideoCall() async {
    final conversationId = widget.conversation.backendId;
    final client = widget.callClient;
    if (conversationId == null || widget.conversation.isSmsRoute) {
      await _showVideoUnavailable(
        title: 'AirText account required',
        message: 'Video calls are available between AirText accounts.',
      );
      return;
    }
    if (client == null) {
      await _showVideoUnavailable(
        title: 'AirText calls unavailable',
        message: 'The AirText calling server is not configured or reachable.',
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VideoCallScreen(
          callerName: widget.conversation.name,
          onJoinCall:
              (
                callScreenContext, {
                required bool microphoneMuted,
                required bool cameraDisabled,
              }) async {
                try {
                  final response = await client.createCall(conversationId);
                  final call = response['data'] as Map<String, dynamic>;
                  if (!callScreenContext.mounted) return;
                  await Navigator.pushReplacement<void, void>(
                    callScreenContext,
                    MaterialPageRoute<void>(
                      builder: (_) => ActiveVideoCallScreen(
                        callClient: client,
                        callId: call['id'] as String,
                        contactName: widget.conversation.name,
                        isCaller: true,
                        startMuted: microphoneMuted,
                        startCameraOff: cameraDisabled,
                      ),
                    ),
                  );
                } on AirTextCallClientException catch (error) {
                  if (callScreenContext.mounted) {
                    ScaffoldMessenger.of(callScreenContext)
                        .showSnackBar(SnackBar(content: Text(error.message)));
                  }
                }
              },
        ),
      ),
    );
  }

  Future<void> _showVideoUnavailable({
    String title = 'Video calls unavailable',
    String message =
        'Connect a video-call provider to enable live video calls.',
  }) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChatActions() async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Conversation'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'contact'),
            child: const Text('Contact details'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'expiry'),
            child: const Text('Disappearing messages'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'contact') await _openContactProfile();
    if (action == 'expiry') await _openContactProfile();
  }

  Future<void> _showAttachmentSheet() async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add to message'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'camera'),
            child: const Text('Take Photo or Video'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'library'),
            child: const Text('Photo & Video Library'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'document'),
            child: const Text('Document'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'location'),
            child: const Text('Location'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'contact'),
            child: const Text('Contact'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case 'camera':
        await _showMediaPicker(source: ImageSource.camera);
      case 'library':
        await _showMediaPicker(source: ImageSource.gallery);
      case 'document':
        await _showUnavailableFeature(
          'Document sharing',
          'The Air app message API currently accepts text messages only.',
        );
      case 'location':
        await _showUnavailableFeature(
          'Location sharing',
          'Location sharing is not connected to the Air app message API yet.',
        );
      case 'contact':
        await _showUnavailableFeature(
          'Contact sharing',
          'Contact cards are not connected to the Air app message API yet.',
        );
    }
  }

  Future<void> _showMediaPicker({required ImageSource source}) async {
    final mediaType = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(source == ImageSource.camera ? 'Camera' : 'Library'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'photo'),
            child: Text(
              source == ImageSource.camera ? 'Take Photo' : 'Choose Photo',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'video'),
            child: Text(
              source == ImageSource.camera ? 'Record Video' : 'Choose Video',
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (mediaType == null) return;

    final picker = ImagePicker();
    final file = mediaType == 'video'
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source);
    if (file == null || !mounted) return;
    await _showUnavailableFeature(
      'Media selected',
      'Media upload is not connected to the Air app message API yet.',
    );
  }

  Future<void> _showUnavailableFeature(String title, String message) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openContactProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContactProfileSheet(
        conversation: widget.conversation,
        disappearingDuration: _disappearingDuration,
        isBlocked: _blocked,
        isReported: _reported,
        shareLastSeen: _shareLastSeen,
        readReceipts: _readReceipts,
        onDurationChanged: (duration) => setState(() {
          _disappearingDuration = duration;
          widget.conversation.disappearingDuration = duration;
        }),
        onBlockChanged: (blocked) => setState(() {
          _blocked = blocked;
          widget.conversation.isBlocked = blocked;
        }),
        onReported: () => setState(() {
          _reported = true;
          widget.conversation.isReported = true;
        }),
        onShareLastSeenChanged: (value) => setState(() {
          _shareLastSeen = value;
          widget.conversation.shareLastSeen = value;
        }),
        onReadReceiptsChanged: (value) {
          setState(() {
            _readReceipts = value;
            widget.conversation.readReceipts = value;
          });
          if (value) _markConversationRead();
        },
        onClearChat: () {
          setState(() => widget.conversation.messages.clear());
          widget.onMessageSent();
        },
      ),
    );
  }
}

class _ShopProductData {
  const _ShopProductData({
    required this.id,
    required this.category,
    required this.icon,
    required this.eyebrow,
    required this.name,
    required this.description,
    required this.price,
    required this.action,
  });

  final String id;
  final String category;
  final IconData icon;
  final String eyebrow;
  final String name;
  final String description;
  final String price;
  final String action;
}

class _AirTextShopPage extends StatefulWidget {
  const _AirTextShopPage();

  @override
  State<_AirTextShopPage> createState() => _AirTextShopPageState();
}

class _AirTextShopPageState extends State<_AirTextShopPage> {
  static const List<_ShopProductData> _products = [
    _ShopProductData(
      id: 'tourism-sms-bot',
      category: 'bots',
      icon: Icons.chat_bubble_outline,
      eyebrow: 'AI assistant',
      name: 'Tourism SMS Bot',
      description: 'Autonomous trip confirmations, promos, and FAQ replies for tour operators and agencies.',
      price: 'TZS 45,000',
      action: 'Install',
    ),
    _ShopProductData(
      id: 'gateway-recovery-suite',
      category: 'gateways',
      icon: Icons.cell_tower,
      eyebrow: 'Operations',
      name: 'Gateway Recovery Suite',
      description: 'Retry logic, routing fallbacks, and delivery alerts to keep your SMS flow resilient.',
      price: 'TZS 120,000',
      action: 'Deploy',
    ),
    _ShopProductData(
      id: 'lead-capture-templates',
      category: 'templates',
      icon: Icons.description_outlined,
      eyebrow: 'Campaigns',
      name: 'Lead Capture Templates',
      description: 'Ready-made response flows for property shows, sales inquiries, and follow-up sequences.',
      price: 'TZS 18,000',
      action: 'Use template',
    ),
  ];

  static const _categories = [
    (label: 'All', value: 'all'),
    (label: 'SMS Bots', value: 'bots'),
    (label: 'Gateways', value: 'gateways'),
    (label: 'Templates', value: 'templates'),
  ];

  final _searchController = TextEditingController();
  final Set<String> _installed = {};
  String _section = 'browse';
  String _category = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? _nexusBackground : _paper;
    final panel = isDark ? _nexusPanel : _lightPanel;
    final border = isDark ? _nexusBorder : _lightBorder;
    final text = isDark ? _nexusText : _ink;
    final muted = isDark ? _nexusMuted : _lightMuted;
    final accent = isDark ? _nexusAccent : _green;

    return ColoredBox(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Air app Shop',
                        style: TextStyle(
                          color: text,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _appCopy(context, 'Marketplace'),
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _appCopy(context, 'Wallet is not connected'),
                  onPressed: null,
                  icon: Icon(Icons.add_card_outlined, color: accent),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: panel,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _appCopy(context, 'Wallet'),
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  Text(
                    _appCopy(context, 'Not connected'),
                    style: TextStyle(
                      color: text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: text, fontSize: 14),
              decoration: InputDecoration(
                hintText: _appCopy(context, 'Search products and services'),
                hintStyle: TextStyle(color: muted, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: muted, size: 20),
                filled: true,
                fillColor: panel,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accent),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: 'browse',
                  label: Text(_appCopy(context, 'Browse')),
                ),
                ButtonSegment(
                  value: 'installed',
                  label: Text(_appCopy(context, 'Installed')),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (selection) =>
                  setState(() => _section = selection.first),
            ),
          ),
          if (_section == 'browse')
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final category in _categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_appCopy(context, category.label)),
                        selected: _category == category.value,
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _category = category.value),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _section == 'browse'
                ? _buildProducts(
                    panel: panel,
                    border: border,
                    text: text,
                    muted: muted,
                    accent: accent,
                  )
                : _buildInstalled(
                    panel: panel,
                    border: border,
                    text: text,
                    muted: muted,
                    accent: accent,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducts({
    required Color panel,
    required Color border,
    required Color text,
    required Color muted,
    required Color accent,
  }) {
    final query = _searchController.text.trim().toLowerCase();
    final products = _products.where((product) {
      final matchesCategory =
          _category == 'all' || product.category == _category;
      final searchable =
          '${product.name} ${product.description} ${product.eyebrow}'
              .toLowerCase();
      return matchesCategory && searchable.contains(query);
    }).toList();

    if (products.isEmpty) {
      return Center(
        child: Text(
          _appCopy(context, 'No verified products are currently published.'),
          style: TextStyle(color: muted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: panel,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(product.icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.eyebrow,
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.price,
                      style: TextStyle(
                        color: text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _selectProduct(product),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(product.action),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstalled({
    required Color panel,
    required Color border,
    required Color text,
    required Color muted,
    required Color accent,
  }) {
    final products = _products
        .where((product) => _installed.contains(product.name))
        .toList();
    if (products.isEmpty) {
      return Center(
        child: Text(
          _appCopy(context, 'No installed services'),
          style: TextStyle(color: muted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: panel,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(product.icon, color: accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ready to configure',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle_outline, color: accent, size: 19),
            ],
          ),
        );
      },
    );
  }

  void _selectProduct(_ShopProductData product) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _appCopy(
            context,
            'Payments are not configured. No purchase was made.',
          ),
        ),
      ),
    );
  }
}

class _CallEntry {
  const _CallEntry({
    required this.name,
    required this.number,
    required this.time,
    required this.direction,
  });

  final String name;
  final String number;
  final String time;
  final String direction;
}

class _PhoneCallPage extends StatefulWidget {
  const _PhoneCallPage({required this.contactName, required this.phoneNumber});

  final String contactName;
  final String phoneNumber;

  @override
  State<_PhoneCallPage> createState() => _PhoneCallPageState();
}

class _PhoneCallPageState extends State<_PhoneCallPage> {
  bool _speakerOn = false;
  bool _videoOn = false;
  bool _muted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07131A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _CallPattern()),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  color: Colors.white,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                  tooltip: 'Close call screen',
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.lock_outline,
                                  color: Colors.white70,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'AIR APP CALL',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const Spacer(),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                          const SizedBox(height: 38),
                          CircleAvatar(
                            radius: 82,
                            backgroundColor: const Color(0xFF020608),
                            child: Text(
                              widget.contactName.trim().isEmpty
                                  ? '?'
                                  : widget.contactName.trim()[0].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFB9E878),
                                fontSize: 54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            widget.contactName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.phoneNumber,
                            style: const TextStyle(
                              color: Color(0xFFAAB8BE),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Voice calling unavailable',
                            style: TextStyle(
                              color: Color(0xFFAAB8BE),
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                            padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141D21),
                              borderRadius: BorderRadius.circular(34),
                              border: Border.all(
                                color: const Color(0xFF26343A),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    _CallControl(
                                      icon: Icons.volume_up_rounded,
                                      label: 'Speaker',
                                      selected: _speakerOn,
                                      onTap: () => setState(
                                        () => _speakerOn = !_speakerOn,
                                      ),
                                    ),
                                    _CallControl(
                                      icon: Icons.videocam_rounded,
                                      label: 'Video',
                                      selected: _videoOn,
                                      onTap: () =>
                                          setState(() => _videoOn = !_videoOn),
                                    ),
                                    _CallControl(
                                      icon: _muted
                                          ? Icons.mic_off_rounded
                                          : Icons.mic_rounded,
                                      label: 'Mute',
                                      selected: _muted,
                                      onTap: () =>
                                          setState(() => _muted = !_muted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    _CallControl(
                                      icon: Icons.more_horiz_rounded,
                                      label: 'More',
                                      onTap: _showMore,
                                    ),
                                    _CallControl(
                                      icon: Icons.share_rounded,
                                      label: 'Share',
                                      onTap: _shareNumber,
                                    ),
                                    _CallControl(
                                      icon: Icons.call_rounded,
                                      label: 'Call',
                                      color: const Color(0xFFB9E878),
                                      foreground: const Color(0xFF101714),
                                      onTap: _startPhoneCall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startPhoneCall() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live voice calling is not connected yet.'),
        ),
      );
    }
  }

  Future<void> _shareNumber() async {
    await Clipboard.setData(ClipboardData(text: widget.phoneNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Number copied.')));
  }

  Future<void> _showMore() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(widget.contactName),
        message: Text(widget.phoneNumber),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.color,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final background =
        color ?? (selected ? Colors.white : const Color(0xFF202A2F));
    final iconColor =
        foreground ?? (selected ? const Color(0xFF101714) : Colors.white);
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(36),
          child: Column(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: background,
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallPattern extends CustomPainter {
  const _CallPattern();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF183039).withValues(alpha: 0.27)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 44.0;
    for (var y = 0.0; y < size.height; y += spacing) {
      for (var x = 0.0; x < size.width; x += spacing) {
        final offset = ((x / spacing).floor() + (y / spacing).floor()) % 2;
        canvas.drawCircle(Offset(x + offset * 18, y + 18), 8, paint);
        canvas.drawLine(Offset(x + 23, y + 12), Offset(x + 31, y + 20), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CallPattern oldDelegate) => false;
}

class _CallsPage extends StatefulWidget {
  const _CallsPage();

  @override
  State<_CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<_CallsPage> {
  final _numberController = TextEditingController();
  final List<_CallEntry> _history = [];

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Calls')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _ListSectionLabel('NEW CALL'),
          _GroupedList(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _numberController,
                        placeholder: 'Phone number',
                        keyboardType: TextInputType.phone,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton.filled(
                      tooltip: 'Call number',
                      onPressed: _numberController.text.trim().isEmpty
                          ? null
                          : () => _call(
                              _numberController.text.trim(),
                              _numberController.text.trim(),
                            ),
                      icon: const Icon(CupertinoIcons.phone),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ListSectionLabel('VIDEO & GROUP CALLS'),
          _GroupedList(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFD9EEE5),
                  foregroundColor: _green,
                  child: const Icon(Icons.video_call_outlined),
                ),
                title: const Text('Start an AirText video call'),
                subtitle: const Text('Start a call from an AirText chat'),
                trailing: const Icon(Icons.lock_outline),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ListSectionLabel('RECENT CALLS'),
          _GroupedList(
            children: [
              if (_history.isEmpty)
                const ListTile(title: Text('No recent calls')),
              for (var index = 0; index < _history.length; index++) ...[
                if (index > 0) const _GroupDivider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE5EFFF),
                    foregroundColor: _green,
                    child: const Icon(CupertinoIcons.phone),
                  ),
                  title: Text(_history[index].name),
                  subtitle: Text(
                    '${_history[index].direction} · ${_history[index].number}',
                  ),
                  trailing: Text(
                    _history[index].time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF77777D),
                    ),
                  ),
                  onTap: () =>
                      _call(_history[index].name, _history[index].number),
                ),
              ],
            ],
          ),
          const Text(
            'AirText video calls are started from direct chats.',
            style: TextStyle(color: Color(0xFF6D6D72), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _call(String name, String number) async {
    final uri = _telephoneUri(number);
    if (uri == null ||
        !await _openVoiceCallScreen(context, number, contactName: name)) {
      return;
    }
    final cleanNumber = uri.path;
    if (!mounted) return;
    setState(() {
      _history.insert(
        0,
        _CallEntry(
          name: name,
          number: cleanNumber,
          time: 'Just now',
          direction: 'Outgoing',
        ),
      );
      _numberController.clear();
    });
  }
}

class _ContactProfileSheet extends StatefulWidget {
  const _ContactProfileSheet({
    required this.conversation,
    required this.disappearingDuration,
    required this.isBlocked,
    required this.isReported,
    required this.shareLastSeen,
    required this.readReceipts,
    required this.onDurationChanged,
    required this.onBlockChanged,
    required this.onReported,
    required this.onShareLastSeenChanged,
    required this.onReadReceiptsChanged,
    required this.onClearChat,
  });

  final ChatConversation conversation;
  final String disappearingDuration;
  final bool isBlocked;
  final bool isReported;
  final bool shareLastSeen;
  final bool readReceipts;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<bool> onBlockChanged;
  final VoidCallback onReported;
  final ValueChanged<bool> onShareLastSeenChanged;
  final ValueChanged<bool> onReadReceiptsChanged;
  final VoidCallback onClearChat;

  @override
  State<_ContactProfileSheet> createState() => _ContactProfileSheetState();
}

class _ContactProfileSheetState extends State<_ContactProfileSheet> {
  late String _duration = widget.disappearingDuration;
  late bool _blocked = widget.isBlocked;
  late bool _reported = widget.isReported;
  String _section = 'Chat';
  late bool _shareLastSeen = widget.shareLastSeen;
  late bool _readReceipts = widget.readReceipts;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: const BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 10, 8),
              child: Row(
                children: [
                  const Spacer(),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7C7CC),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close profile',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    color: const Color(0xFF8E8E93),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 43,
                      backgroundColor: widget.conversation.color,
                      child: Text(
                        widget.conversation.initials,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.conversation.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.conversation.status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6D6D72),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CupertinoSegmentedControl<String>(
                    groupValue: _section,
                    children: const {
                      'Chat': Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        child: Text('Chat'),
                      ),
                      'Privacy': Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        child: Text('Privacy'),
                      ),
                    },
                    onValueChanged: (section) =>
                        setState(() => _section = section),
                  ),
                  const SizedBox(height: 16),
                  if (_section == 'Privacy') ...[
                    const _ListSectionLabel('PRIVACY'),
                    _GroupedList(
                      children: [
                        ListTile(
                          title: const Text('Share Last Seen'),
                          trailing: CupertinoSwitch(
                            value: _shareLastSeen,
                            onChanged: (value) {
                              setState(() => _shareLastSeen = value);
                              widget.onShareLastSeenChanged(value);
                            },
                          ),
                        ),
                        const _GroupDivider(),
                        ListTile(
                          title: const Text('Read Receipts'),
                          trailing: CupertinoSwitch(
                            value: _readReceipts,
                            onChanged: (value) {
                              setState(() => _readReceipts = value);
                              widget.onReadReceiptsChanged(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _GroupedList(
                      children: const [
                        ListTile(
                          leading: Icon(CupertinoIcons.lock_shield),
                          title: Text('Encryption'),
                          subtitle: Text(
                            'Standard SMS is not end-to-end encrypted',
                          ),
                        ),
                        _GroupDivider(),
                        ListTile(
                          leading: Icon(CupertinoIcons.device_phone_portrait),
                          title: Text('Message privacy'),
                          subtitle: Text(
                            'Clearing chat only removes messages from this device',
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _GroupedList(
                      children: [
                        ListTile(
                          leading: const Icon(CupertinoIcons.timer),
                          title: const Text('Disappearing Messages'),
                          subtitle: const Text('New messages on this device'),
                          trailing: Text(
                            _duration,
                            style: const TextStyle(color: _green, fontSize: 13),
                          ),
                          onTap: _chooseDisappearingDuration,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _GroupedList(
                      children: [
                        ListTile(
                          leading: const Icon(CupertinoIcons.trash),
                          title: const Text('Clear Chat'),
                          titleTextStyle: const TextStyle(
                            color: Color(0xFFFF3B30),
                            fontSize: 15,
                          ),
                          onTap: _confirmClearChat,
                        ),
                        const _GroupDivider(),
                        ListTile(
                          leading: Icon(
                            _blocked
                                ? CupertinoIcons.checkmark_circle
                                : CupertinoIcons.hand_raised,
                            color: _blocked ? _green : const Color(0xFFFF3B30),
                          ),
                          title: Text(
                            _blocked ? 'Unblock Contact' : 'Block Contact',
                          ),
                          titleTextStyle: TextStyle(
                            color: _blocked ? _green : const Color(0xFFFF3B30),
                            fontSize: 15,
                          ),
                          onTap: () {
                            final blocked = !_blocked;
                            setState(() => _blocked = blocked);
                            widget.onBlockChanged(blocked);
                            Navigator.pop(context);
                          },
                        ),
                        const _GroupDivider(),
                        ListTile(
                          leading: const Icon(
                            CupertinoIcons.flag,
                            color: Color(0xFFFF3B30),
                          ),
                          title: Text(
                            _reported ? 'Contact Reported' : 'Report Contact',
                          ),
                          titleTextStyle: const TextStyle(
                            color: Color(0xFFFF3B30),
                            fontSize: 15,
                          ),
                          enabled: !_reported,
                          onTap: () {
                            setState(() => _reported = true);
                            widget.onReported();
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear this chat?'),
        content: const Text('Messages will be removed from this device only.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    widget.onClearChat();
    Navigator.pop(context);
  }

  Future<void> _chooseDisappearingDuration() async {
    final duration = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Disappearing Messages'),
        actions: ['Off', '24 hours', '7 days', '90 days']
            .map(
              (duration) => CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, duration),
                child: Text(duration),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (duration == null) return;
    setState(() => _duration = duration);
    widget.onDurationChanged(duration);
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.api,
    required this.conversationId,
    required this.isAirTextRoute,
    required this.accentColor,
    required this.onTranslate,
    required this.onMessageChanged,
  });

  final ChatMessage message;
  final AirTextApi api;
  final int? conversationId;
  final bool isAirTextRoute;
  final Color accentColor;
  final Future<void> Function() onTranslate;
  final VoidCallback onMessageChanged;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  final AudioPlayer _voicePlayer = AudioPlayer();
  Timer? _viewOnceTimer;
  bool _openingViewOnce = false;

  @override
  void dispose() {
    _viewOnceTimer?.cancel();
    unawaited(_voicePlayer.dispose());
    super.dispose();
  }

  Future<void> _playVoiceMessage() async {
    final url = widget.message.mediaUrl;
    if (url == null || widget.message.backendId == null) return;
    final localPath = await widget.api.downloadVoiceMessage(url);
    await _voicePlayer.play(DeviceFileSource(localPath));
    if (widget.message.viewOnce) {
      await _voicePlayer.onPlayerComplete.first;
      try {
        await File(localPath).delete();
      } on FileSystemException {
        debugPrint('Temporary voice cleanup failed.');
      }
      if (!mounted) return;
      setState(() {
        widget.message.mediaUrl = null;
        widget.message.text = 'Opened once';
        widget.message.viewOncePending = false;
        widget.message.viewedAt = DateTime.now();
      });
      widget.onMessageChanged();
    }
  }

  Future<void> _openViewOnce() async {
    final conversationId = widget.conversationId;
    final messageId = widget.message.backendId;
    if (_openingViewOnce || conversationId == null || messageId == null) return;
    setState(() => _openingViewOnce = true);
    try {
      final payload = await widget.api.openViewOnceMessage(
        conversationId,
        messageId,
      );
      if (!mounted) return;
      if (widget.message.messageType == 'voice') {
        setState(() {
          widget.message.mediaUrl = payload['media_url'] as String?;
          widget.message.viewOncePending = false;
          _openingViewOnce = false;
        });
        await _playVoiceMessage();
        return;
      }

      setState(() {
        widget.message.text = payload['body'] as String? ?? '';
        widget.message.viewOncePending = false;
        widget.message.viewedAt = DateTime.now();
        _openingViewOnce = false;
      });
      widget.onMessageChanged();
      _viewOnceTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted) return;
        setState(() => widget.message.text = 'Opened once');
        widget.onMessageChanged();
      });
    } on AirTextApiException catch (error) {
      if (!mounted) return;
      setState(() => _openingViewOnce = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isFailed = message.status == 'failed';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark
      ? (message.isMine ? const Color(0xFF005C4B) : const Color(0xFF202C33))
      : (message.isMine ? const Color(0xFFD9FDD3) : const Color(0xFFFFFFFF));
    final messageTextColor = isDark ? _nexusText : _ink;
    final mutedTextColor = isDark ? _silver : _lightMuted;
    final routeColor = isFailed
        ? const Color(0xFFB3261E)
        : widget.isAirTextRoute
        ? (isDark ? widget.accentColor : _green)
        : (isDark ? const Color(0xFFD9B77A) : const Color(0xFF805A18));
    final routeLabel = isFailed
        ? '${widget.isAirTextRoute ? 'AIR APP' : 'SMS'} · FAILED'
        : widget.isAirTextRoute
        ? 'AIR APP'
        : 'SMS';
    return Column(
      crossAxisAlignment: message.isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: _showMessageActions,
          child: Align(
            alignment: message.isMine
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.82,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(10),
                    topRight: const Radius.circular(10),
                    bottomLeft: Radius.circular(message.isMine ? 10 : 3),
                    bottomRight: Radius.circular(message.isMine ? 3 : 10),
                  ),
                  boxShadow: isDark
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.viewOncePending)
                      TextButton.icon(
                        onPressed: _openingViewOnce ? null : _openViewOnce,
                        icon: Icon(
                          CupertinoIcons.eye,
                          color: widget.accentColor,
                        ),
                        label: Text(
                          _openingViewOnce ? 'Opening…' : 'Open once',
                          style: TextStyle(color: widget.accentColor),
                        ),
                      )
                    else if (message.messageType == 'voice')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: message.mediaUrl == null
                                ? 'View-once audio opened'
                                : 'Play voice message',
                            onPressed: message.mediaUrl == null
                                ? null
                                : _playVoiceMessage,
                            icon: Icon(
                              message.mediaUrl == null
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.play_circle_fill,
                              color: widget.accentColor,
                            ),
                          ),
                          Text(
                            message.mediaUrl == null
                                ? 'Opened once'
                                : 'Voice message',
                            style: TextStyle(color: messageTextColor),
                          ),
                        ],
                      )
                    else
                      Text(
                        message.text.isEmpty && message.viewOnce
                            ? 'Opened once'
                            : message.text,
                        style: TextStyle(
                          color: messageTextColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    if (message.translation != null) ...[
                      const SizedBox(height: 7),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: mutedTextColor.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        child: Text(
                          message.translation!,
                          style: TextStyle(
                            color: messageTextColor,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.time,
                          style: TextStyle(color: mutedTextColor, fontSize: 10),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isFailed
                              ? Icons.error_outline
                              : widget.isAirTextRoute
                              ? Icons.cloud_outlined
                              : Icons.sms_outlined,
                          size: 12,
                          color: routeColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          routeLabel,
                          style: TextStyle(
                            color: routeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (message.isMine && !isFailed) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.status == 'sent'
                                ? Icons.done
                                : Icons.done_all,
                            size: 13,
                            color: message.status == 'read'
                                ? const Color(0xFF4FA3E0)
                                : mutedTextColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (message.reaction != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Align(
              alignment: message.isMine
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? _panelRaised : _lightPanelRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.reaction!,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _showMessageActions() async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Message actions'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'translate'),
            child: const Text('Translate message'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'react'),
            child: const Text('React to message'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'translate') {
      await widget.onTranslate();
    } else if (action == 'react') {
      await _chooseReaction();
    }
  }

  Future<void> _chooseReaction() async {
    const reactions = ['❤️', '😂', '👍', '😮', '😢', '🙏'];
    final reaction = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('React to message'),
        actions: reactions
            .map(
              (emoji) => CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, emoji),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (reaction == null || !mounted) return;
    setState(() => widget.message.reaction = reaction);
  }
}

class _FloatingNavigationDock extends StatelessWidget {
  const _FloatingNavigationDock({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _destinations = [
    (label: 'Chats', icon: CupertinoIcons.chat_bubble_2),
    (label: 'Updates', icon: CupertinoIcons.circle_grid_3x3),
    (label: 'Shop', icon: CupertinoIcons.bag),
    (label: 'Settings', icon: CupertinoIcons.settings),
    (label: 'Profile', icon: CupertinoIcons.person_crop_circle),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, bottomInset + 10),
      child: Center(
        heightFactor: 1,
        child: Container(
          width: width < 460 ? (width - 36).clamp(0.0, 424.0) : 424,
          height: 66,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? _panel : _lightPanel,
            border: Border.all(color: isDark ? _line : _lightBorder),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < _destinations.length; index++)
                Expanded(
                  child: _DockDestination(
                    label: _appCopy(context, _destinations[index].label),
                    icon: _destinations[index].icon,
                    isSelected: selectedIndex == index,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockDestination extends StatelessWidget {
  const _DockDestination({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? _mint : _green;
    final unselectedColor = isDark ? _silver : _lightMuted;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: isSelected
              ? (isDark ? const Color(0xFF26372F) : const Color(0xFFD9EEE5))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: isSelected ? selectedColor : unselectedColor,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? selectedColor : unselectedColor,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusUpdate {
  _StatusUpdate({
    required this.name,
    required this.initials,
    required this.time,
    required this.color,
    required this.message,
    this.isMine = false,
    this.authorEmail,
    this.mediaUrl,
    this.backendId,
    this.hasViewed = false,
    this.views = 0,
    this.likes = 0,
    this.hasLiked = false,
    this.screenshotProtected = false,
    this.viewOnce = false,
  });

  factory _StatusUpdate.fromApi(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    final background = json['background'] as String? ?? '#00a884';
    final body = json['body'] as String? ?? json['caption'] as String? ?? '';

    return _StatusUpdate(
      name: json['author_name'] as String? ?? 'Air app user',
      initials: json['author_initials'] as String? ?? '?',
      time: createdAt == null
          ? 'Just now'
          : _formatMessageTime(createdAt.toLocal()),
      color: Color(
        0xFF000000 | int.parse(background.replaceFirst('#', ''), radix: 16),
      ),
      message: body.isEmpty ? 'Photo status' : body,
      isMine: json['is_mine'] as bool? ?? false,
      authorEmail: json['author_email'] as String?,
      mediaUrl: json['media_url'] as String?,
      backendId: json['id'] as int?,
      hasViewed: json['has_viewed'] as bool? ?? false,
      views: json['views_count'] as int? ?? 0,
      likes: json['likes_count'] as int? ?? 0,
      hasLiked: json['has_liked'] as bool? ?? false,
      screenshotProtected: json['screenshot_protected'] as bool? ?? false,
      viewOnce: json['view_once'] as bool? ?? false,
    );
  }

  final String name;
  final String initials;
  final String time;
  final Color color;
  final String message;
  final bool isMine;
  final String? authorEmail;
  final String? mediaUrl;
  final int? backendId;
  bool hasViewed;
  int views;
  int likes;
  bool hasLiked;
  final bool screenshotProtected;
  final bool viewOnce;
  List<String> viewerNames = [];
  List<String> likerNames = [];
}

class _Community {
  _Community(
    this.name,
    this.description, {
    this.members = 1,
    this.isJoined = true,
  });

  final String name;
  final String description;
  int members;
  bool isJoined;
}

class _UpdatesPage extends StatefulWidget {
  const _UpdatesPage({required this.api, required this.displayName});

  final AirTextApi api;
  final String displayName;

  @override
  State<_UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<_UpdatesPage> {
  _StatusUpdate? _myStatus;
  List<_StatusUpdate> _recentStatuses = [];
  List<_StatusUpdate> _viewedStatuses = [];
  bool _loadingStatuses = false;
  bool _wasAuthenticated = false;
  final List<_Community> _communities = [
    _Community(
      'Air app Community',
      'Announcements and product updates',
      members: 248,
    ),
    _Community(
      'Dar Tech Network',
      'Technology conversations in Dar es Salaam',
      members: 84,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _wasAuthenticated = widget.api.isAuthenticated;
    _loadStatuses();
  }

  @override
  void didUpdateWidget(covariant _UpdatesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_wasAuthenticated && widget.api.isAuthenticated) {
      _loadStatuses();
    }
    _wasAuthenticated = widget.api.isAuthenticated;
  }

  Future<void> _loadStatuses() async {
    if (!widget.api.isAuthenticated) {
      setState(() {
        _myStatus = null;
        _recentStatuses = [];
        _viewedStatuses = [];
      });
      return;
    }

    setState(() => _loadingStatuses = true);
    try {
      final statuses = await widget.api._getStatuses();
      if (!mounted) return;
      setState(() {
        _myStatus = statuses.where((status) => status.isMine).firstOrNull;
        _recentStatuses = statuses
            .where((status) => !status.isMine && !status.hasViewed)
            .toList();
        _viewedStatuses = statuses
            .where((status) => !status.isMine && status.hasViewed)
            .toList();
        _loadingStatuses = false;
      });
    } on AirTextApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadingStatuses = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _ink;
    final mutedColor = isDark ? _silver : _lightMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _appCopy(context, 'Updates'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: _appCopy(context, 'Communities'),
                onPressed: _openCommunities,
                icon: const Icon(CupertinoIcons.person_3, color: _green),
              ),
              IconButton(
                tooltip: _appCopy(context, 'Refresh updates'),
                onPressed: _loadStatuses,
                icon: const Icon(CupertinoIcons.refresh, color: _green),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              _ListSectionLabel(_appCopy(context, 'STATUS')),
              _GroupedList(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    leading: _MyStatusAvatar(
                      hasStatus: _myStatus != null,
                      imageUrl: _myStatus?.mediaUrl,
                    ),
                    title: Text(
                      _appCopy(context, 'My Status'),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      _myStatus == null
                          ? _appCopy(context, 'Tap to add a status update')
                          : '${_myStatus!.time} · ${_myStatus!.views} views',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: mutedColor, fontSize: 12),
                    ),
                    trailing: _myStatus == null
                        ? const Icon(CupertinoIcons.add_circled, color: _green)
                        : const Icon(CupertinoIcons.chevron_right, size: 18),
                    onTap: _myStatus == null
                        ? _addStatus
                        : () => _openStatus(_myStatus!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ListSectionLabel(_appCopy(context, 'RECENT UPDATES')),
              if (!widget.api.isAuthenticated)
                _StatusNotice(
                  message: _appCopy(
                    context,
                    'Sign in to see status updates from your contacts.',
                  ),
                )
              else if (_loadingStatuses)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recentStatuses.isEmpty)
                _StatusNotice(message: _appCopy(context, 'No recent updates.'))
              else
                _GroupedList(
                  children: [
                    for (
                      var index = 0;
                      index < _recentStatuses.length;
                      index++
                    ) ...[
                      if (index > 0) const _GroupDivider(),
                      _StatusTile(
                        initials: _recentStatuses[index].initials,
                        name: _recentStatuses[index].name,
                        time: _recentStatuses[index].time,
                        color: _recentStatuses[index].color,
                        message: _recentStatuses[index].message,
                        hasViewed: _recentStatuses[index].hasViewed,
                        imageUrl: _recentStatuses[index].mediaUrl,
                        onTap: () => _openStatus(_recentStatuses[index]),
                      ),
                    ],
                  ],
                ),
              if (_viewedStatuses.isNotEmpty) ...[
                const SizedBox(height: 20),
                _ListSectionLabel(_appCopy(context, 'VIEWED UPDATES')),
                _GroupedList(
                  children: [
                    for (
                      var index = 0;
                      index < _viewedStatuses.length;
                      index++
                    ) ...[
                      if (index > 0) const _GroupDivider(),
                      _StatusTile(
                        initials: _viewedStatuses[index].initials,
                        name: _viewedStatuses[index].name,
                        time: _viewedStatuses[index].time,
                        color: _viewedStatuses[index].color,
                        message: _viewedStatuses[index].message,
                        hasViewed: true,
                        imageUrl: _viewedStatuses[index].mediaUrl,
                        onTap: () => _openStatus(_viewedStatuses[index]),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ListSectionLabel(_appCopy(context, 'COMMUNITIES')),
                  ),
                  TextButton.icon(
                    onPressed: _openCommunities,
                    icon: const Icon(CupertinoIcons.arrow_right, size: 15),
                    label: const Text('View all'),
                  ),
                ],
              ),
              _GroupedList(
                children: [
                  for (var index = 0; index < _communities.length; index++) ...[
                    if (index > 0) const _GroupDivider(),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE5EFFF),
                        foregroundColor: _green,
                        child: Icon(CupertinoIcons.person_3),
                      ),
                      title: Text(_communities[index].name),
                      subtitle: Text(
                        '${_communities[index].members} members · ${_communities[index].description}',
                      ),
                      onTap: _openCommunities,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addStatus() async {
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('New status'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'text'),
            child: const Text('Write a text status'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'text_once'),
            child: const Text('Write a view-once text status'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'photo'),
            child: const Text('Choose a photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, 'photo_once'),
            child: const Text('Choose a view-once photo'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (!mounted) return;
    if (choice == 'text') await _addTextStatus();
    if (choice == 'text_once') await _addTextStatus(viewOnce: true);
    if (choice == 'photo') await _pickPhotoStatus();
    if (choice == 'photo_once') await _pickPhotoStatus(viewOnce: true);
  }

  Future<void> _addTextStatus({bool viewOnce = false}) async {
    final controller = TextEditingController();
    final status = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('New status'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            maxLength: 120,
            placeholder: 'What is happening?',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Share'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (status == null || status.isEmpty || !mounted) return;
    if (!widget.api.isAuthenticated) {
      _showSignInPrompt();
      return;
    }
    try {
      final created = await widget.api._createTextStatus(
        status,
        viewOnce: viewOnce,
      );
      if (!mounted) return;
      setState(() => _myStatus = created);
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _pickPhotoStatus({bool viewOnce = false}) async {
    if (!widget.api.isAuthenticated) {
      _showSignInPrompt();
      return;
    }
    final photo = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (photo == null) return;
    try {
      final created = await widget.api._createPhotoStatus(
        photo,
        viewOnce: viewOnce,
      );
      if (!mounted) return;
      setState(() => _myStatus = created);
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _showSignInPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in to share status updates.')),
    );
  }

  Future<void> _openStatus(_StatusUpdate status) async {
    var recordedView = status.isMine || status.hasViewed;
    if (!recordedView && status.backendId != null) {
      try {
        await widget.api._markStatusViewed(status.backendId!);
        recordedView = true;
      } on AirTextApiException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    }
    if (!mounted) return;
    if (!status.isMine && recordedView) {
      setState(() {
        status.hasViewed = true;
        _recentStatuses.remove(status);
        if (!_viewedStatuses.contains(status)) _viewedStatuses.add(status);
      });
    }

    final navigator = Navigator.of(context);
    try {
      final route = navigator.push(
        CupertinoPageRoute<void>(
          builder: (_) => _StatusViewerPage(
            status: status,
            api: widget.api,
            onReply: _replyToStatus,
          ),
        ),
      );
      unawaited(_setScreenPrivacy(status.screenshotProtected));
      await route;
    } finally {
      await _setScreenPrivacy(false);
    }
    if (mounted && widget.api.isAuthenticated) await _loadStatuses();
  }

  Future<void> _replyToStatus(_StatusUpdate status, String text) async {
    final email = status.authorEmail;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply is unavailable for this status.')),
      );
      return;
    }

    try {
      final conversation = await widget.api.createConversation(
        email: email,
        name: status.name,
      );
      final conversationId = conversation.backendId;
      if (conversationId == null) return;
      await widget.api.sendMessage(conversationId, text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reply sent to ${status.name}.')),
        );
      }
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _openCommunities() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => _CommunitiesPage(communities: _communities),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.initials,
    required this.name,
    required this.time,
    required this.color,
    required this.message,
    required this.onTap,
    this.hasViewed = false,
    this.imageUrl,
  });

  final String initials;
  final String name;
  final String time;
  final Color color;
  final String message;
  final VoidCallback onTap;
  final bool hasViewed;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: hasViewed ? const Color(0xFF9AA49F) : _green,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 23,
          backgroundColor: color,
          backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
          child: Text(
            initials,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(time, style: const TextStyle(fontSize: 12)),
      ),
      onTap: onTap,
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        message,
        style: TextStyle(color: isDark ? _silver : _lightMuted, fontSize: 13),
      ),
    );
  }
}

class _MyStatusAvatar extends StatelessWidget {
  const _MyStatusAvatar({required this.hasStatus, this.imageUrl});

  final bool hasStatus;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFFE3EAE4),
            backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
            child: imageUrl == null
                ? const Text('A', style: TextStyle(color: _ink))
                : null,
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: hasStatus ? const Color(0xFF71807A) : _green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                hasStatus ? Icons.edit : Icons.add,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusViewerPage extends StatefulWidget {
  const _StatusViewerPage({
    required this.status,
    required this.api,
    required this.onReply,
  });

  final _StatusUpdate status;
  final AirTextApi api;
  final Future<void> Function(_StatusUpdate, String) onReply;

  @override
  State<_StatusViewerPage> createState() => _StatusViewerPageState();
}

class _StatusViewerPageState extends State<_StatusViewerPage> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_loadViewers());
  }

  Future<void> _loadViewers() async {
    final statusId = widget.status.backendId;
    if (!widget.status.isMine || statusId == null) return;
    try {
      final viewers = await widget.api.getStatusViewers(statusId);
      final likers = await widget.api.getStatusLikers(statusId);
      if (!mounted) return;
      setState(() {
        widget.status.viewerNames = viewers
            .map((viewer) => viewer['name'] as String? ?? 'Air app user')
            .toList();
        widget.status.likerNames = likers
            .map((liker) => liker['name'] as String? ?? 'Air app user')
            .toList();
      });
    } on AirTextApiException {
      return;
    }
  }

  Future<void> _toggleLike() async {
    final statusId = widget.status.backendId;
    if (statusId == null) return;
    try {
      final result = widget.status.hasLiked
          ? await widget.api.unlikeStatus(statusId)
          : await widget.api.likeStatus(statusId);
      if (!mounted) return;
      setState(() {
        widget.status.hasLiked = result['liked'] as bool? ?? false;
        widget.status.likes =
            result['likes_count'] as int? ?? widget.status.likes;
      });
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: status.color,
              child: Text(
                status.initials,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.name, style: const TextStyle(fontSize: 15)),
                Text(
                  status.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF75827D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const LinearProgressIndicator(
            value: 1,
            minHeight: 2,
            color: Colors.white,
            backgroundColor: Color(0x66FFFFFF),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: status.color,
              alignment: Alignment.center,
              child: status.mediaUrl == null
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        status.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Image.network(
                      status.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Text(
                              'Could not load status media.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                    ),
            ),
          ),
          if (status.isMine) _buildInsights(status),
          if (!status.isMine)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _commentController,
                        placeholder: 'Reply',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        style: const TextStyle(color: Colors.white),
                        placeholderStyle: const TextStyle(
                          color: Color(0xFFB8C1BC),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF202A25),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        onSubmitted: (_) => _sendReply(),
                      ),
                    ),
                    if (!widget.status.isMine)
                      IconButton(
                        tooltip: widget.status.hasLiked
                            ? 'Unlike status'
                            : 'Like status',
                        onPressed: _toggleLike,
                        icon: Icon(
                          widget.status.hasLiked
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: widget.status.hasLiked
                              ? const Color(0xFFFF667A)
                              : _mint,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Send reply',
                      onPressed: _sendReply,
                      icon: const Icon(
                        CupertinoIcons.arrow_up_circle_fill,
                        color: _mint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInsights(_StatusUpdate status) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF101714),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status insights',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(CupertinoIcons.eye, size: 18, color: _green),
              const SizedBox(width: 6),
              Text(
                '${status.views} views',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                CupertinoIcons.heart,
                size: 18,
                color: Color(0xFFFF667A),
              ),
              const SizedBox(width: 6),
              Text(
                '${status.likes} likes',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          for (final name in status.viewerNames)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                name,
                style: const TextStyle(color: Color(0xFFB8C1BC), fontSize: 12),
              ),
            ),
          if (status.likerNames.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Liked by',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final name in status.likerNames)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFB8C1BC),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
          if (status.views == 0)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Your contacts can view this update for 24 hours.',
                style: TextStyle(fontSize: 11, color: Color(0xFFB8C1BC)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendReply() async {
    final reply = _commentController.text.trim();
    if (reply.isEmpty || widget.status.isMine) return;
    _commentController.clear();
    await widget.onReply(widget.status, reply);
  }
}

class _CommunitiesPage extends StatefulWidget {
  const _CommunitiesPage({required this.communities});

  final List<_Community> communities;

  @override
  State<_CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<_CommunitiesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Communities'),
        actions: [
          IconButton(
            tooltip: 'Create community',
            onPressed: _createCommunity,
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ListSectionLabel('YOUR COMMUNITIES'),
          _GroupedList(
            children: [
              for (
                var index = 0;
                index < widget.communities.length;
                index++
              ) ...[
                if (index > 0) const _GroupDivider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE5EFFF),
                    foregroundColor: _green,
                    child: Icon(CupertinoIcons.person_3),
                  ),
                  title: Text(widget.communities[index].name),
                  subtitle: Text(
                    '${widget.communities[index].members} members · ${widget.communities[index].description}',
                  ),
                  trailing: TextButton(
                    onPressed: () => setState(() {
                      widget.communities[index].isJoined =
                          !widget.communities[index].isJoined;
                      widget.communities[index].members +=
                          widget.communities[index].isJoined ? 1 : -1;
                    }),
                    child: Text(
                      widget.communities[index].isJoined ? 'Joined' : 'Join',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Create community',
        onPressed: _createCommunity,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        child: const Icon(CupertinoIcons.add),
      ),
    );
  }

  Future<void> _createCommunity() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final result = await showCupertinoDialog<(String, String)?>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Create community'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: nameController,
              placeholder: 'Community name',
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: descriptionController,
              placeholder: 'Description',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, (
                  name,
                  descriptionController.text.trim(),
                ));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    descriptionController.dispose();
    if (result == null || !mounted) return;
    setState(
      () => widget.communities.add(
        _Community(result.$1, result.$2, isJoined: true),
      ),
    );
  }
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({
    required this.displayName,
    required this.username,
    required this.about,
    required this.imageBytes,
    required this.imageUrl,
    required this.onSave,
    required this.onOpenAccount,
  });

  final String displayName;
  final String username;
  final String about;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final Future<void> Function(String, String, String, Uint8List?) onSave;
  final VoidCallback onOpenAccount;

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  late final _nameController = TextEditingController(text: widget.displayName);
  late final _usernameController = TextEditingController(text: widget.username);
  late final _aboutController = TextEditingController(text: widget.about);
  Uint8List? _imageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 14, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Account settings',
                onPressed: widget.onOpenAccount,
                icon: const Icon(CupertinoIcons.settings, color: _green),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfilePhoto,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFFE5EFFF),
                        foregroundColor: const Color(0xFF245781),
                        backgroundImage: _imageBytes == null
                            ? (widget.imageUrl == null
                                  ? null
                                  : NetworkImage(widget.imageUrl!))
                            : MemoryImage(_imageBytes!),
                        child: _imageBytes == null
                            ? Text(
                                _nameController.text.isEmpty
                                    ? 'A'
                                    : _nameController.text[0].toUpperCase(),
                                style: const TextStyle(fontSize: 28),
                              )
                            : null,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickProfilePhoto,
                      icon: const Icon(CupertinoIcons.photo_camera),
                      label: const Text('Change photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _ListSectionLabel('YOUR PROFILE'),
              _GroupedList(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: CupertinoTextField(
                      controller: _nameController,
                      placeholder: 'Name',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(CupertinoIcons.person, size: 18),
                      ),
                      padding: const EdgeInsets.all(12),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const _GroupDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: CupertinoTextField(
                      controller: _usernameController,
                      placeholder: '@username',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(CupertinoIcons.at, size: 18),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const _GroupDivider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: CupertinoTextField(
                      controller: _aboutController,
                      placeholder: 'About',
                      maxLines: 3,
                      maxLength: 140,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(CupertinoIcons.text_alignleft, size: 18),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(CupertinoIcons.checkmark),
                label: Text(_isSaving ? 'Saving…' : 'Save profile'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const _ListSectionLabel('ACCOUNT'),
              _GroupedList(
                children: [
                  ListTile(
                    leading: const Icon(
                      CupertinoIcons.person_crop_circle_badge_checkmark,
                      color: _green,
                    ),
                    title: const Text('Account'),
                    subtitle: const Text('Registration, sign out and data'),
                    trailing: const Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                    ),
                    onTap: widget.onOpenAccount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickProfilePhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 720,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    if (name.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and username are required.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        name,
        username.startsWith('@') ? username : '@$username',
        _aboutController.text.trim(),
        _imageBytes,
      );
    } on AirTextApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved on this device.')),
    );
  }
}

class _AccountPage extends StatefulWidget {
  const _AccountPage({
    required this.api,
    required this.appearance,
    required this.onAuthenticated,
    required this.onSaveProfile,
    required this.onSignOut,
    required this.onDeleteLocalData,
    required this.onDeleteAccount,
  });

  final AirTextApi api;
  final AirTextAppearance appearance;
  final Future<void> Function(Map<String, dynamic> user) onAuthenticated;
  final Future<void> Function(String name, String email, Uint8List? photo)
  onSaveProfile;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteLocalData;
  final Future<void> Function() onDeleteAccount;

  @override
  State<_AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<_AccountPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneCodeController = TextEditingController();
  int _step = 0;
  String _language = 'Kiswahili (Tanzania)';
  String _countryCode = '+255';
  bool _phoneCodeRequested = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _pendingUser;
  String? _loginChallenge;
  String? _phoneHint;
  Uint8List? _profilePhoto;

  static const _countries = {
    'Tanzania': '+255',
    'Kenya': '+254',
    'Uganda': '+256',
    'United States': '+1',
    'United Kingdom': '+44',
  };

  bool get _isSwahili => _language.toLowerCase().startsWith('kiswahili');

  String _copy(String english, String swahili) =>
      _isSwahili ? swahili : english;

  @override
  void initState() {
    super.initState();
    _step = widget.api.isAuthenticated ? 5 : 7;
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _language =
          preferences.getString('airtext.language') ?? 'Kiswahili (Tanzania)';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _phoneCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 5 || _step == 7) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(_appCopy(context, 'Account')),
        ),
        body: _step == 5 ? _buildAccountSettings() : _buildAccountAccess(),
      );
    }

    final stepNumber = _step == 6 ? 2 : (_step < 3 ? _step : 3);
    return CupertinoTheme(
      data: CupertinoTheme.of(context)
          .copyWith(primaryColor: const Color(0xFF00A99D)),
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            _step == 0
                ? 'AirText'
                : _copy('Step $stepNumber of 3', 'Hatua $stepNumber kati ya 3'),
          ),
          leading: CupertinoNavigationBarBackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailing: _step > 0
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isSubmitting ? null : _goBack,
                  child: Text(_copy('Back', 'Rudi')),
                )
              : null,
        ),
        child: _buildOnboardingStep(),
      ),
    );
  }

  Widget _buildOnboardingStep() {
    return switch (_step) {
      0 => _buildWelcomeStep(),
      1 => _buildEmailStep(),
      2 => _buildEmailCodeStep(),
      3 => _buildProfileStep(),
      4 => _buildPhoneStep(),
      6 => _buildLoginPhoneStep(),
      _ => const SizedBox.shrink(),
    };
  }

  String get _formattedPhoneNumber {
    final nationalNumber = _phoneController.text
        .replaceAll(RegExp(r'\D'), '')
        .replaceFirst(RegExp(r'^0+'), '');
    return '$_countryCode$nationalNumber';
  }

  Future<void> _setLanguage(String value) async {
    setState(() => _language = value);
    await widget.appearance.setLanguage(value);
  }

  Future<void> _chooseLanguage() async {
    final selected = await Navigator.of(context).push<String>(
      CupertinoPageRoute<String>(
        builder: (_) => LanguageSelectorScreen(api: widget.api),
      ),
    );
    if (selected != null && selected.isNotEmpty) {
      await _setLanguage(selected);
    }
  }

  Widget _buildWelcomeStep() {
    return WelcomeScreen(
      language: _language,
      onChooseLanguage: _chooseLanguage,
      onContinue: () => setState(() => _step = 1),
    );
  }

  Widget _buildEmailStep() {
    return EmailRegisterScreen(
      controller: _emailController,
      isSwahili: _isSwahili,
      isSubmitting: _isSubmitting,
      onSubmit: _requestOtp,
    );
  }

  Widget _buildEmailCodeStep() {
    return EmailOtpScreen(
      email: _emailController.text.trim(),
      controller: _codeController,
      isSwahili: _isSwahili,
      isSubmitting: _isSubmitting,
      onVerify: _verifyOtp,
      onResend: _requestOtp,
    );
  }

  Widget _buildProfileStep() {
    return ProfileSetupScreen(
      controller: _nameController,
      photo: _profilePhoto,
      isSwahili: _isSwahili,
      isSubmitting: _isSubmitting,
      onPickPhoto: _pickProfilePhoto,
      onContinue: _saveProfileAndContinue,
    );
  }

  Widget _buildPhoneStep() {
    return PhoneVerifyScreen(
      phoneController: _phoneController,
      codeController: _phoneCodeController,
      countryCode: _countryCode,
      countries: _countries,
      codeRequested: _phoneCodeRequested,
      isLoginChallenge: false,
      phoneHint: null,
      isSwahili: _isSwahili,
      isSubmitting: _isSubmitting,
      onCountryChanged: (value) => setState(() => _countryCode = value),
      onPhoneChanged: (_) => setState(() {}),
      onSubmit: _phoneCodeRequested
          ? () => _verifyPhoneOtp(_formattedPhoneNumber)
          : () => _requestPhoneOtp(_formattedPhoneNumber),
    );
  }

  Widget _buildLoginPhoneStep() {
    return PhoneVerifyScreen(
      phoneController: _phoneController,
      codeController: _phoneCodeController,
      countryCode: _countryCode,
      countries: _countries,
      codeRequested: true,
      isLoginChallenge: true,
      phoneHint: _phoneHint,
      isSwahili: _isSwahili,
      isSubmitting: _isSubmitting,
      onCountryChanged: (_) {},
      onPhoneChanged: (_) {},
      onSubmit: _verifyPhoneLoginOtp,
    );
  }

  Widget _buildAccountSettings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const _ListSectionLabel('THIS DEVICE'),
        _GroupedList(
          children: [
            ListTile(
              leading: const Icon(
                CupertinoIcons.arrow_right_square,
                color: _green,
              ),
              title: const Text('Sign out'),
              subtitle: const Text(
                'End this device session; your account and data stay saved',
              ),
              onTap: () => _confirmAction(
                title: 'Sign out?',
                message: 'Only this device will be signed out. Your account, profile, contacts, conversations and messages remain saved. Sign in again with the same email to restore your account.',
                action: 'Sign out',
                onConfirm: widget.onSignOut,
              ),
            ),
            const _GroupDivider(),
            ListTile(
              leading: const Icon(
                CupertinoIcons.person_crop_circle_badge_xmark,
                color: Color(0xFFFF3B30),
              ),
              title: const Text('Delete account'),
              subtitle: const Text(
                'Permanently remove your AirText account and server data',
              ),
              titleTextStyle: const TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 15,
              ),
              onTap: _confirmAccountDeletion,
            ),
            const _GroupDivider(),
            ListTile(
              leading: const Icon(
                CupertinoIcons.delete,
                color: Color(0xFFFF3B30),
              ),
              title: const Text('Delete local app data'),
              subtitle: const Text(
                'Remove this device profile and saved contacts',
              ),
              titleTextStyle: const TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 15,
              ),
              onTap: () => _confirmAction(
                title: 'Delete local data?',
                message: 'This removes the profile and saved contacts from this device, not the Air app account.',
                action: 'Delete',
                onConfirm: widget.onDeleteLocalData,
                destructive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountAccess() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const _ListSectionLabel('ACCOUNT ACCESS'),
        _GroupedList(
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.person_badge_plus),
              title: const Text('Create an account'),
              subtitle: const Text('Verify your email and phone number'),
              onTap: () => setState(() => _step = 0),
            ),
            const _GroupDivider(),
            ListTile(
              leading: const Icon(CupertinoIcons.lock),
              title: const Text('Sign in'),
              subtitle: const Text('Continue with your verified email'),
              onTap: () => setState(() => _step = 1),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _ListSectionLabel('THIS DEVICE'),
        _GroupedList(
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.delete),
              title: const Text('Delete local app data'),
              subtitle: const Text('Remove this device profile and contacts'),
              onTap: () => _confirmAction(
                title: 'Delete local data?',
                message: 'This removes the profile and saved contacts from this device.',
                action: 'Delete',
                onConfirm: widget.onDeleteLocalData,
                destructive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickProfilePhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 720,
    );
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (mounted) setState(() => _profilePhoto = bytes);
  }

  void _goBack() {
    setState(() {
      if (_step == 6) {
        _step = 2;
      } else if (_step == 2) {
        _step = 1;
      } else if (_step > 0) {
        _step--;
      }
    });
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage(
        _copy('Enter a valid email address.', 'Weka barua pepe sahihi.'),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.api.requestOtp(email);
      if (!mounted) return;
      setState(() {
        _step = 2;
      });
      _showMessage(
        _copy(
          'A verification code has been sent.',
          'Msimbo wa uthibitishaji umetumwa.',
        ),
      );
    } on AirTextApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showMessage('Enter the 6-digit code from your email.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await widget.api.verifyOtp(email: email, code: code);
      final user = response['user'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _pendingUser = user;
        if (response['requires_phone_verification'] == true) {
          _loginChallenge = response['challenge'] as String?;
          _phoneHint = response['phone_hint'] as String?;
          _step = 6;
        } else {
          _nameController.text = user['name'] as String? ?? '';
          _step = 3;
        }
      });
    } on AirTextApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveProfileAndContinue() async {
    final name = _nameController.text.trim();
    final user = _pendingUser;
    if (name.isEmpty || user == null) {
      _showMessage(
        _copy('Enter your name to continue.', 'Weka jina lako ili uendelee.'),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final updatedUser = await widget.api.updateProfile(name);
      await widget.onSaveProfile(
        name,
        updatedUser['email'] as String? ?? _emailController.text.trim(),
        _profilePhoto,
      );
      if (!mounted) return;
      setState(() {
        _pendingUser = updatedUser;
        _step = 4;
      });
    } on AirTextApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _requestPhoneOtp(String phoneNumber) async {
    if (phoneNumber.replaceAll(RegExp(r'\D'), '').length < 8) {
      _showMessage(
        _copy('Enter a valid phone number.', 'Weka namba sahihi ya simu.'),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.api.requestPhoneOtp(phoneNumber);
      if (!mounted) return;
      setState(() => _phoneCodeRequested = true);
      _showMessage(
        _copy(
          'A verification code has been sent by SMS.',
          'Msimbo wa uthibitishaji umetumwa kwa SMS.',
        ),
      );
    } on AirTextApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyPhoneLoginOtp() async {
    final challenge = _loginChallenge;
    final code = _phoneCodeController.text.trim();
    if (challenge == null || code.length != 6) {
      _showMessage(
        _copy(
          'Enter the 6-digit SMS code.',
          'Weka msimbo wa SMS wa tarakimu 6.',
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = await widget.api.verifyPhoneLoginOtp(
        challenge: challenge,
        code: code,
      );
      await widget.onAuthenticated(user);
      if (mounted) Navigator.of(context).pop();
    } on AirTextApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyPhoneOtp(String phoneNumber) async {
    final code = _phoneCodeController.text.trim();
    if (code.length != 6) {
      _showMessage(
        _copy(
          'Enter the 6-digit SMS code.',
          'Weka msimbo wa SMS wa tarakimu 6.',
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await widget.api.verifyPhoneOtp(phoneNumber: phoneNumber, code: code);
      if (_pendingUser == null) {
        if (mounted) setState(() => _step = 5);
      } else {
        await _finishOnboarding();
      }
    } on AirTextApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _finishOnboarding() async {
    final user = _pendingUser;
    if (user == null) return;
    await widget.onAuthenticated(user);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('airtext.onboarding-complete', true);
    if (mounted) Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required String action,
    required Future<void> Function() onConfirm,
    bool destructive = false,
  }) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed == true) await onConfirm();
  }

  Future<void> _confirmAccountDeletion() async {
    final confirmationController = TextEditingController();
    final confirmationPhrase = _isSwahili ? 'FUTA' : 'DELETE';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            icon: const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Color(0xFFFF3B30),
              size: 32,
            ),
            title: Text(
              _copy('Permanently delete account?', 'Futa akaunti kabisa?'),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.68,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _copy(
                        'This action cannot be undone. AirText will permanently remove your account profile and sign-in sessions, contacts, conversations and messages, statuses and uploaded media, channels and posts, call records, device notifications, subscriptions, and other account-linked data from the active system database. You will be signed out on every device. To use AirText again, you must register a new account; this deleted account cannot be restored.',
                        'Hatua hii haiwezi kutenguliwa. AirText itafuta kabisa wasifu wa akaunti yako na vipindi vya kuingia, anwani, mazungumzo na ujumbe, status na faili ulizopakia, channels na machapisho, kumbukumbu za simu, arifa za vifaa, subscriptions, pamoja na data nyingine zilizounganishwa na akaunti yako kwenye mfumo hai. Utaondolewa kwenye akaunti kwenye vifaa vyote. Ili kutumia AirText tena utahitaji kusajili akaunti mpya; akaunti hii iliyofutwa haiwezi kurejeshwa.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _copy(
                        'This does not erase copies other people saved outside AirText or data retained in backups according to the service retention policy.',
                        'Hii haifuti nakala ambazo watu wengine walihifadhi nje ya AirText, wala data inayoweza kubaki kwenye backups kulingana na sera ya muda wa kuhifadhi data.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _copy(
                        'Type $confirmationPhrase to confirm permanent deletion.',
                        'Andika $confirmationPhrase kuthibitisha ufutaji wa kudumu.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: confirmationController,
                      placeholder: confirmationPhrase,
                      autocorrect: false,
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_copy('Cancel', 'Ghairi')),
              ),
              TextButton(
                onPressed:
                    confirmationController.text.trim() == confirmationPhrase
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD32F2F),
                ),
                child: Text(_copy('Delete account', 'Futa akaunti')),
              ),
            ],
          );
        },
      ),
    );
    confirmationController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onDeleteAccount();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage({
    required this.appearance,
    required this.onOpenChatTheme,
  });

  final AirTextAppearance appearance;
  final VoidCallback onOpenChatTheme;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Settings',
        middle: Text('Appearance'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('APP THEME'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Appearance'),
                  child: CupertinoSlidingSegmentedControl<ThemeMode>(
                    groupValue: appearance.themeMode,
                    children: const {
                      ThemeMode.system: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7),
                        child: Text('System'),
                      ),
                      ThemeMode.light: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7),
                        child: Text('Light'),
                      ),
                      ThemeMode.dark: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7),
                        child: Text('Dark'),
                      ),
                    },
                    onValueChanged: (mode) {
                      if (mode != null) appearance.setThemeMode(mode);
                    },
                  ),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('IN-APP LOGO'),
              children: [
                for (final option in [
                  (style: AirTextLogoStyle.mark, title: 'Air app mark'),
                  (style: AirTextLogoStyle.monogram, title: 'Monogram'),
                  (style: AirTextLogoStyle.signal, title: 'Signal'),
                ])
                  CupertinoListTile(
                    leading: AirTextLogo(style: option.style, size: 32),
                    title: Text(option.title),
                    trailing: appearance.logoStyle == option.style
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: _green,
                            size: 18,
                          )
                        : null,
                    onTap: () => appearance.setLogoStyle(option.style),
                  ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('HOME SCREEN ICON'),
              children: [
                CupertinoListTile(
                  leading: Image.asset(
                    'assets/airtext_app_icon.png',
                    width: 32,
                    height: 32,
                  ),
                  title: const Text('Air app icon'),
                  additionalInfo: const Text('Choose icon'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _chooseLauncherIcon(context),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('MESSAGES'),
              children: [
                CupertinoListTile(
                  leading: const Icon(
                    CupertinoIcons.chat_bubble_2,
                    color: _green,
                  ),
                  title: const Text('Chat Theme'),
                  additionalInfo: const Text('Color and wallpaper'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: onOpenChatTheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseLauncherIcon(BuildContext context) async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      if (!await DynamicAppIconFlutterPlus.supportsAlternateIcons) return;
      final availableIcons =
          await DynamicAppIconFlutterPlus.getAvailableIcons();
      if (!context.mounted) return;
      final choice = await showCupertinoModalPopup<String>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Home screen icon'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, 'default'),
              child: const Text('Air app'),
            ),
            if (availableIcons.contains('midnight'))
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, 'midnight'),
                child: const Text('Air app Midnight'),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      );
      if (choice == null) return;

      await DynamicAppIconFlutterPlus.setAlternateIconName(
        choice == 'default' ? null : choice,
        showAlert: true,
        deferUntilBackground: defaultTargetPlatform == TargetPlatform.android,
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Icon could not be changed'),
          content: Text(error.message ?? 'The selected icon is unavailable.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _ChatThemePage extends StatelessWidget {
  const _ChatThemePage({required this.appearance});

  final AirTextAppearance appearance;

  static const _swatches = [
    (name: 'Air app Mint', color: Color(0xFF9BE2BD)),
    (name: 'Ocean Blue', color: Color(0xFF78B7E1)),
    (name: 'Soft Rose', color: Color(0xFFF08DA0)),
    (name: 'Signal Amber', color: Color(0xFFD9B77A)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Appearance',
        middle: Text('Chat Theme'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('PREVIEW'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isDark ? _obsidian : _paper,
                      borderRadius: BorderRadius.circular(14),
                      image: appearance.chatWallpaper == null
                          ? null
                          : DecorationImage(
                              image: MemoryImage(appearance.chatWallpaper!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: (isDark ? _obsidian : Colors.white).withValues(
                          alpha: 0.9,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Message preview',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.arrow_up_circle_fill,
                              color: appearance.chatAccent,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('ACCENT COLOR'),
              children: [
                for (final swatch in _swatches)
                  CupertinoListTile(
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: swatch.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(swatch.name),
                    trailing: appearance.chatAccent == swatch.color
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: _green,
                            size: 18,
                          )
                        : null,
                    onTap: () => appearance.setChatAccent(swatch.color),
                  ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              header: const Text('WALLPAPER'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.photo, color: _green),
                  title: const Text('Choose from Photos'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => _chooseWallpaper(context),
                ),
                if (appearance.chatWallpaper != null)
                  CupertinoListTile(
                    leading: const Icon(
                      CupertinoIcons.trash,
                      color: CupertinoColors.systemRed,
                    ),
                    title: const Text('Remove Wallpaper'),
                    onTap: () => appearance.setChatWallpaper(null),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseWallpaper(BuildContext context) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1400,
      maxHeight: 1800,
    );
    if (image == null) return;
    await appearance.setChatWallpaper(await image.readAsBytes());
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.api,
    required this.appearance,
    required this.onOpenProfile,
    required this.onOpenAccount,
    required this.onOpenAppearance,
  });

  final AirTextApi api;
  final AirTextAppearance appearance;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenAppearance;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F3EE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Text(
              _appCopy(context, 'Settings'),
              style: TextStyle(
                color: _ink,
                fontSize: 29,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              children: [
                _ListSectionLabel(_appCopy(context, 'ACCOUNT')),
                _GroupedList(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline,
                      title: _appCopy(context, 'Profile'),
                      subtitle: _appCopy(context, 'Photo, username and about'),
                      onTap: onOpenProfile,
                    ),
                    const _GroupDivider(),
                    _SettingsTile(
                      icon: Icons.manage_accounts_outlined,
                      title: _appCopy(context, 'Account'),
                      subtitle: _appCopy(
                        context,
                        'Registration, sign out and data',
                      ),
                      onTap: onOpenAccount,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ListSectionLabel(_appCopy(context, 'DISPLAY')),
                _GroupedList(
                  children: [
                    _SettingsTile(
                      icon: Icons.palette_outlined,
                      title: _appCopy(context, 'Appearance'),
                      subtitle:
                          '${appearance.themeMode.name} · ${_appCopy(context, 'Chat Theme')}',
                      onTap: onOpenAppearance,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ListSectionLabel(_appCopy(context, 'MESSAGING')),
                _GroupedList(
                  children: [
                    _SettingsTile(
                      icon: Icons.sms_outlined,
                      title: _appCopy(context, 'GSM & SMS Protocol'),
                      subtitle: _appCopy(context, 'Manage offline messaging'),
                      onTap: () => _openSettings(context, 'GSM & SMS Protocol'),
                    ),
                    const _GroupDivider(),
                    _SettingsTile(
                      icon: Icons.notifications_none,
                      title: _appCopy(context, 'Notifications'),
                      subtitle: _appCopy(context, 'Message & call tones'),
                      onTap: () => _openSettings(context, 'Notifications'),
                    ),
                    const _GroupDivider(),
                    _SettingsTile(
                      icon: Icons.storage_outlined,
                      title: _appCopy(context, 'Storage and data'),
                      subtitle: _appCopy(
                        context,
                        'Chats, media, auto-download',
                      ),
                      onTap: () => _openSettings(context, 'Storage and data'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ListSectionLabel(_appCopy(context, 'PRIVACY & ACCESS')),
                _GroupedList(
                  children: [
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: _appCopy(context, 'Privacy'),
                      subtitle: _appCopy(
                        context,
                        'Last seen, profile visibility',
                      ),
                      onTap: () => _openSettings(context, 'Privacy'),
                    ),
                    const _GroupDivider(),
                    _SettingsTile(
                      icon: Icons.accessibility_new_outlined,
                      title: _appCopy(context, 'Accessibility'),
                      subtitle: _appCopy(
                        context,
                        'Text size, motion and display',
                      ),
                      onTap: () => _openSettings(context, 'Accessibility'),
                    ),
                    const _GroupDivider(),
                    _SettingsTile(
                      icon: Icons.language_outlined,
                      title: _appCopy(context, 'App language'),
                      subtitle: appearance.language,
                      onTap: () => _openSettings(context, 'App language'),
                    ),
                    const _GroupDivider(),
                    _SettingsTile(
                      icon: Icons.group_add_outlined,
                      title: _appCopy(context, 'Invite friend'),
                      subtitle: _appCopy(
                        context,
                        'Share AirText with a friend',
                      ),
                      onTap: () => _openSettings(context, 'Invite friend'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ListSectionLabel(_appCopy(context, 'MORE')),
                _GroupedList(
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: _appCopy(context, 'Help & feedback'),
                      subtitle: _appCopy(
                        context,
                        'Reports, policy and support',
                      ),
                      onTap: () => _openSettings(context, 'Help & feedback'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context, String section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SettingsDetailPage(
          section: section,
          api: api,
          appearance: appearance,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE7F0EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _green, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF75827D), fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF9AA49F),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _SettingsDetailPage extends StatefulWidget {
  const _SettingsDetailPage({
    required this.section,
    required this.api,
    required this.appearance,
  });

  final String section;
  final AirTextApi api;
  final AirTextAppearance appearance;

  @override
  State<_SettingsDetailPage> createState() => _SettingsDetailPageState();
}

class _SettingsDetailPageState extends State<_SettingsDetailPage> {
  bool _offlineMessaging = true;
  bool _deliveryReceipts = true;
  String _defaultPayloadPrefix = 'MSG:';
  bool _useLessDataForCalls = false;
  String _uploadQuality = 'hd';
  String _autoDownloadQuality = 'auto';
  String _mobileDataDownloads = 'photos';
  String _wifiDownloads = 'all';
  String _roamingDownloads = 'none';
  bool _gatewayConfigured = false;
  bool _testingGateway = false;
  String? _gatewaySender;
  String _gatewayStatus = 'Not checked';
  bool _messageSounds = true;
  bool _callSounds = true;
  String _messageTone = 'Chime';
  String _callTone = 'Soft echo';
  bool _twoStepVerification = false;
  bool _autoDownloadPhotos = true;
  bool _autoDownloadVideos = true;
  bool _autoDownloadStickers = false;
  bool _autoDownloadVoiceNotes = true;
  bool _largeText = false;
  bool _reducedMotion = true;
  bool _highContrast = false;
  String _appLanguage = 'Kiswahili (Tanzania)';
  String _lastSeen = 'Everyone';
  String _profilePicture = 'My contacts';
  String _about = 'My contacts';
  String _links = 'My contacts';
  String _status = 'Everyone';
  bool _defaultMessageTimer = true;
  bool _groups = true;
  bool _liveLocation = false;
  bool _contactBlock = true;
  bool _appLock = false;
  bool _chatLock = false;
  bool _allowCameraEffects = true;
  bool _advanced = false;
  bool _privacyCheckup = true;
  String _cacheSize = 'Calculating...';
  String _deviceName = 'Detecting device...';
  String _deviceSystem = 'Reading operating system';
  Map<String, dynamic>? _storageSummary;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedLanguage());
    unawaited(_loadSavedSettings());
    unawaited(_loadCacheSize());
    unawaited(_loadGatewayConfiguration());
    unawaited(_loadStorageSummary());
    unawaited(_loadDeviceInfo());
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final info = await _deviceInfoChannel.invokeMapMethod<String, String>(
        'getDeviceInfo',
      );
      if (!mounted || info == null) return;
      setState(() {
        _deviceName = '${info['manufacturer'] ?? 'Device'} ${info['model'] ?? ''}'
            .trim();
        _deviceSystem = info['system'] ?? 'Android';
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _deviceName = switch (defaultTargetPlatform) {
          TargetPlatform.iOS => 'Apple device',
          TargetPlatform.android => 'Android device',
          _ => 'This device',
        };
        _deviceSystem = Platform.operatingSystem;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _deviceName = 'This device';
        _deviceSystem = Platform.operatingSystem;
      });
    }
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localStorageSettings = await StorageSettingsService.loadSettings();
    final photos = await StorageSettingsService.getPhotosDownload();
    final videos = await StorageSettingsService.getVideosDownload();
    final stickers = await StorageSettingsService.getStickersDownload();
    final voice = await StorageSettingsService.getVoiceNotesDownload();
    Map<String, dynamic>? remotePreferences;
    if (widget.api.isAuthenticated) {
      try {
        remotePreferences = await widget.api.getUserPreferences();
      } on AirTextApiException {
        remotePreferences = null;
      }
    }
    if (!mounted) return;
    final rawRemoteMessaging = remotePreferences?['messaging_settings'];
    final remoteMessaging = rawRemoteMessaging is Map<String, dynamic>
        ? rawRemoteMessaging
        : <String, dynamic>{};
    final rawRemoteStorage = remotePreferences?['storage_settings'];
    final remoteStorage = rawRemoteStorage is Map<String, dynamic>
        ? rawRemoteStorage
        : <String, dynamic>{};
    setState(() {
      _offlineMessaging =
          remoteMessaging['sms_fallback_enabled'] as bool? ??
          prefs.getBool('sms_fallback_enabled') ??
          true;
      _deliveryReceipts =
          remoteMessaging['delivery_receipts'] as bool? ??
          prefs.getBool('sms_delivery_receipts') ??
          true;
      _defaultPayloadPrefix =
          remoteMessaging['default_payload_prefix'] as String? ??
          prefs.getString('sms_payload_prefix') ??
          'MSG:';
      _useLessDataForCalls =
          remoteStorage['use_less_data_for_calls'] as bool? ??
          localStorageSettings['use_less_data_for_calls'] as bool;
      _uploadQuality =
          remoteStorage['upload_quality'] as String? ??
          localStorageSettings['upload_quality'] as String;
      _autoDownloadQuality =
          remoteStorage['auto_download_quality'] as String? ??
          localStorageSettings['auto_download_quality'] as String;
      _mobileDataDownloads =
          remoteStorage['mobile_data_downloads'] as String? ??
          localStorageSettings['mobile_data_downloads'] as String;
      _wifiDownloads =
          remoteStorage['wifi_downloads'] as String? ??
          localStorageSettings['wifi_downloads'] as String;
      _roamingDownloads =
          remoteStorage['roaming_downloads'] as String? ??
          localStorageSettings['roaming_downloads'] as String;
      _autoDownloadPhotos =
          remoteStorage['auto_download_photos'] as bool? ?? photos;
      _autoDownloadVideos =
          remoteStorage['auto_download_videos'] as bool? ?? videos;
      _autoDownloadStickers =
          remoteStorage['auto_download_stickers'] as bool? ?? stickers;
      _autoDownloadVoiceNotes =
          remoteStorage['auto_download_voice'] as bool? ?? voice;
      _messageSounds = widget.appearance.messageSoundsEnabled;
      _callSounds = widget.appearance.callSoundsEnabled;
      _largeText = widget.appearance.largeText;
      _reducedMotion = widget.appearance.reducedMotion;
      _highContrast = widget.appearance.highContrast;
      _appLock = widget.appearance.appLockEnabled;
      _chatLock = widget.appearance.chatLockEnabled;
      _messageTone = widget.appearance.messageTone;
      _callTone = widget.appearance.callTone;
      _lastSeen =
          remotePreferences?['last_seen_visibility'] as String? ??
          prefs.getString('airtext.privacy.last-seen') ??
          'Everyone';
      _profilePicture =
          remotePreferences?['profile_picture_visibility'] as String? ??
          prefs.getString('airtext.privacy.profile-picture') ??
          'My contacts';
      _about =
          remotePreferences?['about_visibility'] as String? ??
          prefs.getString('airtext.privacy.about') ??
          'My contacts';
      _links =
          remotePreferences?['links_visibility'] as String? ??
          prefs.getString('airtext.privacy.links') ??
          'My contacts';
      _status =
          remotePreferences?['status_visibility'] as String? ??
          prefs.getString('airtext.privacy.status') ??
          'Everyone';
      _defaultMessageTimer =
          remotePreferences?['disappearing_messages'] as bool? ??
          prefs.getBool(AirTextAppearance.disappearingMessagesKey) ??
          false;
    });
  }

  Future<void> _loadCacheSize() async {
    final size = await CacheManagerService.getCacheSize();
    if (!mounted) return;
    setState(() => _cacheSize = size);
  }

  Future<void> _persistSmsFallback(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_fallback_enabled', value);
    if (!mounted) return;
    setState(() => _offlineMessaging = value);
    await _persistMessagingSettings();
  }

  Future<void> _persistMessagingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_delivery_receipts', _deliveryReceipts);
    await prefs.setString('sms_payload_prefix', _defaultPayloadPrefix);
    if (!widget.api.isAuthenticated) return;
    try {
      await widget.api.updateSmsGatewayPreferences(
        messagingSettings: {
          'default_payload_prefix': _defaultPayloadPrefix,
          'delivery_receipts': _deliveryReceipts,
          'sms_fallback_enabled': _offlineMessaging,
        },
      );
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved on this phone only: ${error.message}')),
        );
      }
    }
  }

  Future<void> _persistStorageSettings() async {
    await StorageSettingsService.saveSettings(
      useLessDataForCalls: _useLessDataForCalls,
      uploadQuality: _uploadQuality,
      autoDownloadQuality: _autoDownloadQuality,
      mobileDataDownloads: _mobileDataDownloads,
      wifiDownloads: _wifiDownloads,
      roamingDownloads: _roamingDownloads,
      autoDownloadPhotos: _autoDownloadPhotos,
      autoDownloadVideos: _autoDownloadVideos,
      autoDownloadStickers: _autoDownloadStickers,
      autoDownloadVoice: _autoDownloadVoiceNotes,
    );
    if (!widget.api.isAuthenticated) return;
    try {
      await widget.api.updateSmsGatewayPreferences(
        storageSettings: {
          'use_less_data_for_calls': _useLessDataForCalls,
          'upload_quality': _uploadQuality,
          'auto_download_quality': _autoDownloadQuality,
          'mobile_data_downloads': _mobileDataDownloads,
          'wifi_downloads': _wifiDownloads,
          'roaming_downloads': _roamingDownloads,
          'auto_download_photos': _autoDownloadPhotos,
          'auto_download_videos': _autoDownloadVideos,
          'auto_download_stickers': _autoDownloadStickers,
          'auto_download_voice': _autoDownloadVoiceNotes,
        },
      );
    } on AirTextApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved on this phone only: ${error.message}')),
        );
      }
    }
  }

  Future<void> _setStorageOption(String setting, String value) async {
    setState(() {
      switch (setting) {
        case 'upload_quality':
          _uploadQuality = value;
        case 'auto_download_quality':
          _autoDownloadQuality = value;
        case 'mobile_data_downloads':
          _mobileDataDownloads = value;
        case 'wifi_downloads':
          _wifiDownloads = value;
        case 'roaming_downloads':
          _roamingDownloads = value;
      }
    });
    await _persistStorageSettings();
  }

  Future<void> _setDefaultPayloadPrefix(String value) async {
    setState(() => _defaultPayloadPrefix = value);
    await _persistMessagingSettings();
  }

  Future<void> _setDeliveryReceipts(bool value) async {
    setState(() => _deliveryReceipts = value);
    await _persistMessagingSettings();
  }

  Future<void> _setLessDataForCalls(bool value) async {
    setState(() => _useLessDataForCalls = value);
    await _persistStorageSettings();
  }

  Future<void> _loadGatewayConfiguration() async {
    if (!widget.api.isAuthenticated) return;
    try {
      final gateway = await widget.api.getSmsGateway();
      if (!mounted) return;
      setState(() {
        _gatewayConfigured = gateway['configured'] as bool? ?? false;
        _gatewaySender = gateway['sender_number'] as String?;
        _gatewayStatus = _gatewayConfigured ? 'Ready' : 'Not configured';
      });
    } on AirTextApiException catch (error) {
      if (mounted) setState(() => _gatewayStatus = error.message);
    }
  }

  Future<void> _loadStorageSummary() async {
    if (!widget.api.isAuthenticated) return;
    try {
      final summary = await widget.api.getStorageSummary();
      if (mounted) setState(() => _storageSummary = summary);
    } on AirTextApiException {
      // The device cache controls remain available if account storage is offline.
    }
  }

  Future<void> _testSmsGateway() async {
    if (!widget.api.isAuthenticated || _testingGateway) return;
    setState(() {
      _testingGateway = true;
      _gatewayStatus = 'Checking connection...';
    });
    try {
      final message = await widget.api.testSmsGateway();
      if (mounted) setState(() => _gatewayStatus = message);
    } on AirTextApiException catch (error) {
      if (mounted) setState(() => _gatewayStatus = error.message);
    } finally {
      if (mounted) setState(() => _testingGateway = false);
    }
  }

  Future<void> _persistPhotoDownload(bool value) async {
    await StorageSettingsService.setPhotosDownload(value);
    if (!mounted) return;
    setState(() => _autoDownloadPhotos = value);
    await _persistStorageSettings();
  }

  Future<void> _persistVideoDownload(bool value) async {
    await StorageSettingsService.setVideosDownload(value);
    if (!mounted) return;
    setState(() => _autoDownloadVideos = value);
    await _persistStorageSettings();
  }

  Future<void> _persistStickerDownload(bool value) async {
    await StorageSettingsService.setStickersDownload(value);
    if (!mounted) return;
    setState(() => _autoDownloadStickers = value);
    await _persistStorageSettings();
  }

  Future<void> _persistVoiceDownload(bool value) async {
    await StorageSettingsService.setVoiceNotesDownload(value);
    if (!mounted) return;
    setState(() => _autoDownloadVoiceNotes = value);
    await _persistStorageSettings();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _appLanguage =
          prefs.getString('airtext.language') ?? 'Kiswahili (Tanzania)';
    });
  }

  Future<void> _saveLanguage(String language) async {
    await widget.appearance.setLanguage(language);
    if (widget.api.isAuthenticated) {
      try {
        await widget.api.updateUserPreferences(appLanguage: language);
      } catch (_) {
        // The server sync is best-effort for app language until the backend is reachable.
      }
    }
    if (!mounted) return;
    setState(() => _appLanguage = language);
  }

  Future<void> _syncPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('airtext.privacy.last-seen', _lastSeen);
    await prefs.setString('airtext.privacy.profile-picture', _profilePicture);
    await prefs.setString('airtext.privacy.about', _about);
    await prefs.setString('airtext.privacy.links', _links);
    await prefs.setString('airtext.privacy.status', _status);
    await prefs.setBool(
      AirTextAppearance.disappearingMessagesKey,
      _defaultMessageTimer,
    );
    if (!widget.api.isAuthenticated) return;
    try {
      await widget.api.updateUserPreferences(
        lastSeenVisibility: _lastSeen,
        profilePictureVisibility: _profilePicture,
        aboutVisibility: _about,
        linksVisibility: _links,
        statusVisibility: _status,
        disappearingMessages: _defaultMessageTimer,
      );
    } catch (_) {
      // Keep the local UI state even if the remote sync is temporarily unavailable.
    }
  }

  Future<void> _setBiometricLock(String key, bool value) async {
    final authenticated = await AppLockService.authenticateUser();
    if (!mounted) return;
    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication was not completed.'),
        ),
      );
      return;
    }

    await widget.appearance.setBooleanPreference(key, value);
    if (!mounted) return;
    setState(() {
      if (key == AirTextAppearance.appLockKey) _appLock = value;
      if (key == AirTextAppearance.chatLockKey) _chatLock = value;
    });
  }

  Future<void> _setAccessibilityPreference(String key, bool value) async {
    await widget.appearance.setBooleanPreference(key, value);
    if (!mounted) return;
    setState(() {
      if (key == AirTextAppearance.largeTextKey) _largeText = value;
      if (key == AirTextAppearance.reducedMotionKey) _reducedMotion = value;
      if (key == AirTextAppearance.highContrastKey) _highContrast = value;
    });
  }

  Future<void> _chooseMessageTone(String value) async {
    await widget.appearance.setMessageTone(value);
    if (!mounted) return;
    setState(() => _messageTone = value);
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
    if (platform != null && widget.api.isAuthenticated) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await widget.api.registerPushToken(
            token,
            platform,
            messageTone: value,
          );
        }
      } on Exception {
        // Push tone sync is optional until Firebase is configured.
      }
    }
    await NotificationSoundService.playMessageSound(preview: true);
  }

  Future<void> _chooseCallTone(String value) async {
    await widget.appearance.setCallTone(value);
    if (!mounted) return;
    setState(() => _callTone = value);
    await NotificationSoundService.startCallSound();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await NotificationSoundService.stopCallSound();
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final storage = _storageSummary?['storage'] as Map<String, dynamic>?;
    final networkUsage =
      _storageSummary?['network_usage'] as Map<String, dynamic>?;
    final networkBytes =
      (networkUsage?['uploaded_bytes'] as int? ?? 0) +
      (networkUsage?['downloaded_bytes'] as int? ?? 0);
    final accountUsage = storage == null || networkUsage == null
      ? 'Sign in to view account usage'
      : '${storage['message_count']} messages · ${_formatDataSize(networkBytes)} used this month';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3ED),
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
        title: Text(_appCopy(context, section)),
        titleTextStyle: const TextStyle(
          color: _ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          if (section == 'Account') ...[
            const _ListSectionLabel('SECURITY'),
            _GroupedList(
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Two-step verification'),
                  subtitle: const Text('Add another layer of account security'),
                  value: _twoStepVerification,
                  onChanged: (value) =>
                      setState(() => _twoStepVerification = value),
                ),
                const _GroupDivider(),
                const ListTile(
                  title: Text('Phone number'),
                  subtitle: Text('+255 7•• ••• •••'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ] else if (section == 'GSM & SMS Protocol') ...[
            const _ListSectionLabel('CHATS & PAYLOAD PREFERENCES'),
            _GroupedList(
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Send through phone SIM'),
                  subtitle: const Text(
                    'Send regular SMS from this device; recipients do not need AirText',
                  ),
                  value: _offlineMessaging,
                  onChanged: _persistSmsFallback,
                ),
                const _GroupDivider(),
                ListTile(
                  title: const Text('Default payload prefix'),
                  subtitle: Text(_defaultPayloadPrefix),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _showOptionSheet(
                    'Default payload prefix',
                    const ['MSG:', 'STAT:', 'ACK:'],
                    (value) => unawaited(_setDefaultPayloadPrefix(value)),
                    _defaultPayloadPrefix,
                  ),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Delivery receipts'),
                  subtitle: const Text('Keep delivery events in chat history'),
                  value: _deliveryReceipts,
                  onChanged: _setDeliveryReceipts,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _ListSectionLabel('SMS GATEWAY & TRANSPORT'),
            _GroupedList(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_input_antenna),
                  title: const Text('Transport driver'),
                  subtitle: Text(
                    _gatewayConfigured
                        ? 'Twilio · ${_gatewaySender ?? 'Sender configured'}'
                        : 'Twilio · ${widget.api.isAuthenticated ? _gatewayStatus : 'Sign in to check server configuration'}',
                  ),
                  trailing: const Icon(Icons.lock_outline),
                ),
                const _GroupDivider(),
                ListTile(
                  title: const Text('Connection status'),
                  subtitle: Text(_gatewayStatus),
                  trailing: _testingGateway
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: widget.api.isAuthenticated ? _testSmsGateway : null,
                ),
                const _GroupDivider(),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    onPressed: widget.api.isAuthenticated && !_testingGateway
                        ? _testSmsGateway
                        : null,
                    icon: const Icon(Icons.network_check),
                    label: const Text('Test gateway connection'),
                  ),
                ),
              ],
            ),
          ] else if (section == 'Notifications') ...[
            const _ListSectionLabel('SOUNDS'),
            _GroupedList(
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Message sounds'),
                  subtitle: Text('Incoming messages · $_messageTone'),
                  value: _messageSounds,
                  onChanged: (value) async {
                    await widget.appearance.setMessageSoundsEnabled(value);
                    if (mounted) setState(() => _messageSounds = value);
                  },
                ),
                if (_messageSounds)
                  ListTile(
                    title: const Text('Message tone'),
                    subtitle: Text(_messageTone),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showOptionSheet(
                      'Message tone',
                      NotificationSoundService.messageTones.keys.toList(),
                      (value) => unawaited(_chooseMessageTone(value)),
                      _messageTone,
                    ),
                  ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Call sounds'),
                  subtitle: Text('Incoming calls · $_callTone'),
                  value: _callSounds,
                  onChanged: (value) async {
                    await widget.appearance.setCallSoundsEnabled(value);
                    if (mounted) setState(() => _callSounds = value);
                  },
                ),
                if (_callSounds)
                  ListTile(
                    title: const Text('Call ringtone'),
                    subtitle: Text(_callTone),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showOptionSheet(
                      'Call ringtone',
                      NotificationSoundService.messageTones.keys.toList(),
                      (value) => unawaited(_chooseCallTone(value)),
                      _callTone,
                    ),
                  ),
              ],
            ),
          ] else if (section == 'Storage and data') ...[
            const _ListSectionLabel('MEDIA DISPLAY'),
            _GroupedList(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text(_deviceName),
                  subtitle: Text('$_deviceSystem · detected on this device'),
                  trailing: IconButton(
                    tooltip: 'Refresh device details',
                    onPressed: _loadDeviceInfo,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _ListSectionLabel('DATA USAGE'),
            _GroupedList(
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Use less data for calls'),
                  value: _useLessDataForCalls,
                  onChanged: _setLessDataForCalls,
                ),
                const _GroupDivider(),
                ListTile(
                  title: const Text('Network usage & cache'),
                  subtitle: Text('Device cache: $_cacheSize · $accountUsage'),
                  onTap: _loadStorageSummary,
                  trailing: TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      await CacheManagerService.clearCache();
                      await _loadCacheSize();
                      if (messenger != null && mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cache has been cleared successfully.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Clear cache'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _ListSectionLabel('MEDIA QUALITY'),
            _GroupedList(
              children: [
                ListTile(
                  title: const Text('Upload quality'),
                  subtitle: Text(_uploadQuality == 'hd' ? 'HD' : 'Standard'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showOptionSheet(
                    'Upload quality',
                    const ['Standard', 'HD'],
                    (value) => unawaited(
                      _setStorageOption('upload_quality', value.toLowerCase()),
                    ),
                    _uploadQuality == 'hd' ? 'HD' : 'Standard',
                  ),
                ),
                const _GroupDivider(),
                ListTile(
                  title: const Text('Auto-download quality'),
                  subtitle: Text(
                    _autoDownloadQuality == 'high' ? 'High' : 'Auto',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showOptionSheet(
                    'Auto-download quality',
                    const ['Auto', 'High'],
                    (value) => unawaited(
                      _setStorageOption(
                        'auto_download_quality',
                        value.toLowerCase(),
                      ),
                    ),
                    _autoDownloadQuality == 'high' ? 'High' : 'Auto',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _ListSectionLabel('AUTO-DOWNLOAD'),
            _GroupedList(
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Photos'),
                  value: _autoDownloadPhotos,
                  onChanged: _persistPhotoDownload,
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Videos'),
                  value: _autoDownloadVideos,
                  onChanged: _persistVideoDownload,
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Stickers'),
                  value: _autoDownloadStickers,
                  onChanged: _persistStickerDownload,
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Voice notes'),
                  value: _autoDownloadVoiceNotes,
                  onChanged: _persistVoiceDownload,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _ListSectionLabel('DOWNLOAD OVER'),
            _GroupedList(
              children: [
                for (final setting in const [
                  ('mobile_data_downloads', 'Mobile data'),
                  ('wifi_downloads', 'Wi-Fi'),
                  ('roaming_downloads', 'Roaming'),
                ]) ...[
                  if (setting.$1 != 'mobile_data_downloads')
                    const _GroupDivider(),
                  ListTile(
                    title: Text(setting.$2),
                    subtitle: Text(
                      _downloadLabel(switch (setting.$1) {
                        'mobile_data_downloads' => _mobileDataDownloads,
                        'wifi_downloads' => _wifiDownloads,
                        _ => _roamingDownloads,
                      }),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showOptionSheet(
                      '${setting.$2} downloads',
                      const ['None', 'Photos', 'All media'],
                      (value) => unawaited(
                        _setStorageOption(
                          setting.$1,
                          switch (value) {
                            'None' => 'none',
                            'Photos' => 'photos',
                            _ => 'all',
                          },
                        ),
                      ),
                      _downloadLabel(switch (setting.$1) {
                        'mobile_data_downloads' => _mobileDataDownloads,
                        'wifi_downloads' => _wifiDownloads,
                        _ => _roamingDownloads,
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ] else if (section == 'Accessibility') ...[
            const _ListSectionLabel('DISPLAY ACCESS'),
            _GroupedList(
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Large text'),
                  value: _largeText,
                  onChanged: (value) => _setAccessibilityPreference(
                    AirTextAppearance.largeTextKey,
                    value,
                  ),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Reduced motion'),
                  value: _reducedMotion,
                  onChanged: (value) => _setAccessibilityPreference(
                    AirTextAppearance.reducedMotionKey,
                    value,
                  ),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('High contrast'),
                  value: _highContrast,
                  onChanged: (value) => _setAccessibilityPreference(
                    AirTextAppearance.highContrastKey,
                    value,
                  ),
                ),
                const _GroupDivider(),
                const ListTile(
                  leading: Icon(Icons.record_voice_over_outlined),
                  title: Text('Screen reader support'),
                  subtitle: Text(
                    'TalkBack and VoiceOver are controlled in device settings. Air app exposes native Flutter semantics.',
                  ),
                ),
              ],
            ),
          ] else if (section == 'App language') ...[
            _ListSectionLabel(_appCopy(context, 'LANGUAGE')),
            _GroupedList(
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.globe),
                  title: Text(_appLanguage),
                  subtitle: Text(
                    _appCopy(context, 'Tap to change app language'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final selected = await Navigator.of(context).push<String>(
                      CupertinoPageRoute<String>(
                        builder: (_) => LanguageSelectorScreen(api: widget.api),
                      ),
                    );
                    if (selected != null && selected.isNotEmpty) {
                      await _saveLanguage(selected);
                    }
                  },
                ),
              ],
            ),
          ] else if (section == 'Invite friend') ...[
            const _ListSectionLabel('SHARE'),
            _GroupedList(
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.person_badge_plus),
                  title: const Text('Invite via link'),
                  subtitle: const Text('Share an invite code with a friend'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showShareInviteDialog(),
                ),
              ],
            ),
          ] else if (section == 'Privacy') ...[
            const _ListSectionLabel('WHO CAN SEE'),
            _GroupedList(
              children: [
                _PrivacyRow(
                  title: 'Last seen and online',
                  value: _lastSeen,
                  options: const ['Everyone', 'My contacts', 'Nobody'],
                  onTap: () => _showOptionSheet(
                    'Last seen and online',
                    const ['Everyone', 'My contacts', 'Nobody'],
                    (value) {
                      setState(() => _lastSeen = value);
                      unawaited(_syncPrivacySettings());
                    },
                    _lastSeen,
                  ),
                ),
                const _GroupDivider(),
                _PrivacyRow(
                  title: 'Profile picture',
                  value: _profilePicture,
                  options: const ['Everyone', 'My contacts', 'Nobody'],
                  onTap: () => _showOptionSheet(
                    'Profile picture',
                    const ['Everyone', 'My contacts', 'Nobody'],
                    (value) {
                      setState(() => _profilePicture = value);
                      unawaited(_syncPrivacySettings());
                    },
                    _profilePicture,
                  ),
                ),
                const _GroupDivider(),
                _PrivacyRow(
                  title: 'About',
                  value: _about,
                  options: const ['Everyone', 'My contacts', 'Nobody'],
                  onTap: () => _showOptionSheet(
                    'About',
                    const ['Everyone', 'My contacts', 'Nobody'],
                    (value) {
                      setState(() => _about = value);
                      unawaited(_syncPrivacySettings());
                    },
                    _about,
                  ),
                ),
                const _GroupDivider(),
                _PrivacyRow(
                  title: 'Links',
                  value: _links,
                  options: const ['Everyone', 'My contacts', 'Nobody'],
                  onTap: () => _showOptionSheet(
                    'Links',
                    const ['Everyone', 'My contacts', 'Nobody'],
                    (value) {
                      setState(() => _links = value);
                      unawaited(_syncPrivacySettings());
                    },
                    _links,
                  ),
                ),
                const _GroupDivider(),
                _PrivacyRow(
                  title: 'Status',
                  value: _status,
                  options: const ['Everyone', 'My contacts', 'Nobody'],
                  onTap: () => _showOptionSheet(
                    'Status',
                    const ['Everyone', 'My contacts', 'Nobody'],
                    (value) {
                      setState(() => _status = value);
                      unawaited(_syncPrivacySettings());
                    },
                    _status,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _ListSectionLabel('SECURITY TOOLS'),
            _GroupedList(
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Default message timer'),
                  subtitle: const Text('Auto-delete messages by default'),
                  value: _defaultMessageTimer,
                  onChanged: (value) async {
                    setState(() => _defaultMessageTimer = value);
                    await widget.appearance.setBooleanPreference(
                      AirTextAppearance.disappearingMessagesKey,
                      value,
                    );
                    await _syncPrivacySettings();
                  },
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Groups'),
                  value: _groups,
                  onChanged: (value) => setState(() => _groups = value),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Live location'),
                  value: _liveLocation,
                  onChanged: (value) => setState(() => _liveLocation = value),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Contacts block'),
                  value: _contactBlock,
                  onChanged: (value) => setState(() => _contactBlock = value),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('App lock'),
                  value: _appLock,
                  onChanged: (value) =>
                      _setBiometricLock(AirTextAppearance.appLockKey, value),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Chat lock'),
                  value: _chatLock,
                  onChanged: (value) =>
                      _setBiometricLock(AirTextAppearance.chatLockKey, value),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Allow camera effects'),
                  value: _allowCameraEffects,
                  onChanged: (value) =>
                      setState(() => _allowCameraEffects = value),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Advanced'),
                  value: _advanced,
                  onChanged: (value) => setState(() => _advanced = value),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Privacy checkup'),
                  value: _privacyCheckup,
                  onChanged: (value) => setState(() => _privacyCheckup = value),
                ),
              ],
            ),
          ] else if (section == 'Help & feedback') ...[
            const _ListSectionLabel('SUPPORT'),
            _GroupedList(
              children: [
                ListTile(
                  leading: const Icon(CupertinoIcons.chat_bubble_text_fill),
                  title: const Text('Send feedback'),
                  subtitle: const Text('Tell us what to improve'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFeedbackDialog(),
                ),
                const _GroupDivider(),
                ListTile(
                  leading: const Icon(CupertinoIcons.doc_text),
                  title: const Text('Terms and privacy policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showGenericInfo(
                    'Terms & privacy policy',
                    'This section will open the app policy document.',
                  ),
                ),
                const _GroupDivider(),
                ListTile(
                  leading: const Icon(CupertinoIcons.flag_fill),
                  title: const Text('Channel reports'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showGenericInfo(
                    'Channel reports',
                    'Submit channel abuse reports here.',
                  ),
                ),
                const _GroupDivider(),
                ListTile(
                  leading: const Icon(CupertinoIcons.info_circle_fill),
                  title: const Text('App info'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showGenericInfo(
                    'App info',
                    'AirText v1.0 · Offline-first communication platform.',
                  ),
                ),
                const _GroupDivider(),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.person_crop_circle_badge_exclam,
                  ),
                  title: const Text('Contact report'),
                  subtitle: const Text('Report or block a contact'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReportDialog(),
                ),
              ],
            ),
          ] else ...[
            const _ListSectionLabel('AIR APP'),
            _GroupedList(
              children: const [
                ListTile(
                  title: Text('Payload protocol updates'),
                  subtitle: Text('Air app protocol v1.0'),
                ),
                _GroupDivider(),
                ListTile(
                  title: Text('About Air app'),
                  subtitle: Text('Offline-first messaging for everyone'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showShareInviteDialog() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Invite friend'),
        content: const Text(
          'Share your AirText invite link or copy the code to send to a friend.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: 'https://airtext.app/invite/airtext'),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite link copied.')),
              );
            },
            child: const Text('Copy link'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFeedbackDialog() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Send feedback'),
        content: const Text(
          'We value your feedback. Share any bugs, ideas, or suggestions to improve AirText.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback draft saved.')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportDialog() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Contact report'),
        content: const Text(
          'Report this contact for abuse or spam. You can also block them from further interacting with you.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact reported and blocked.')),
              );
            },
            child: const Text('Report & block'),
          ),
        ],
      ),
    );
  }

  Future<void> _showOptionSheet(
    String title,
    List<String> options,
    ValueChanged<String> onSelect,
    String currentValue,
  ) async {
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (final option in options)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, option),
              isDefaultAction: option == currentValue,
              child: Text(option),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (selected != null) onSelect(selected);
  }

  String _downloadLabel(String value) => switch (value) {
    'none' => 'None',
    'photos' => 'Photos',
    'all' => 'All media',
    _ => 'Auto',
  };

  String _formatDataSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showGenericInfo(String title, String message) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({
    required this.title,
    required this.value,
    required this.options,
    required this.onTap,
  });

  final String title;
  final String value;
  final List<String> options;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: _green, fontSize: 13)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: _lightMuted, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}

class LanguageSelectorScreen extends StatefulWidget {
  const LanguageSelectorScreen({super.key, required this.api});

  final AirTextApi api;

  @override
  State<LanguageSelectorScreen> createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends State<LanguageSelectorScreen> {
  static const List<String> _allLanguages = [
    'Kiswahili (Tanzania)',
    'English',
    'French (Français)',
    'Spanish (Español)',
    'Arabic (العربية)',
    'Mandarin Chinese (中文)',
    'Portuguese (Português)',
    'Hindi (हिन्दी)',
    'Russian (Русский)',
    'German (Deutsch)',
    'Japanese (日本語)',
    'Korean (한국어)',
    'Italian (Italiano)',
    'Turkish (Türkçe)',
    'Vietnamese (Tiếng Việt)',
    'Urdu (اردو)',
    'Persian (فارسی)',
    'Polish (Polski)',
    'Ukrainian (Українська)',
    'Dutch (Nederlands)',
    'Greek (Ελληνικά)',
    'Bengali (বাংলা)',
    'Punjabi (ਪੰਜਾਬੀ)',
    'Javanese (Basa Jawa)',
    'Telugu (తెలుగు)',
    'Marathi (मराठी)',
    'Tamil (தமிழ்)',
    'Gujarati (ગુજરાતી)',
    'Hausa (Harshen Hausa)',
    'Yoruba (Yorùbá)',
    'Igbo (Asụsụ Igbo)',
    'Amharic (አማርኛ)',
    'Zulu (isiZulu)',
    'Xhosa (isiXhosa)',
    'Somali (Soomaaliga)',
    'Malay / Indonesian (Bahasa)',
    'Tagalog (Filipino)',
    'Thai (ไทย)',
    'Hungarian (Magyar)',
    'Czech (Čeština)',
    'Swedish (Svenska)',
    'Danish (Dansk)',
    'Finnish (Suomi)',
    'Norwegian (Norsk)',
    'Romanian (Română)',
    'Hebrew (עברית)',
    'Bulgarian (Български)',
    'Serbian (Српски)',
    'Croatian (Hrvatski)',
    'Slovak (Slovenčina)',
  ];

  late TextEditingController _searchController;
  List<String> _filteredLanguages = _allLanguages;
  String _selectedLanguage = 'Kiswahili (Tanzania)';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterLanguages);
    unawaited(_loadSavedLanguage());
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedLanguage =
          prefs.getString('airtext.language') ?? 'Kiswahili (Tanzania)';
      _filteredLanguages = _allLanguages;
    });
  }

  void _filterLanguages() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredLanguages = query.isEmpty
          ? _allLanguages
          : _allLanguages
                .where((language) => language.toLowerCase().contains(query))
                .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLanguages);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languages = _filteredLanguages;
    final strings = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Color(0xFFF9FAFB),
        middle: Text(
          strings.selectLanguage,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoSearchTextField(
                controller: _searchController,
                placeholder: strings.searchLanguage,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                backgroundColor: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: ListView.separated(
                    itemCount: languages.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFF2F2F7)),
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      final isSelected = _selectedLanguage == language;
                      return CupertinoListTile(
                        title: Text(
                          language,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF007AFF)
                                : const Color(0xFF1C1C1E),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                CupertinoIcons.checkmark,
                                color: Color(0xFF007AFF),
                              )
                            : null,
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('airtext.language', language);
                          if (widget.api.isAuthenticated) {
                            try {
                              await widget.api.updateUserPreferences(
                                appLanguage: language,
                              );
                            } catch (_) {
                              // Best-effort server sync so the app remains responsive.
                            }
                          }
                          if (!mounted) return;
                          setState(() => _selectedLanguage = language);
                          if (navigator.canPop()) {
                            navigator.pop(language);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListSectionLabel extends StatelessWidget {
  const _ListSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? _silver : _lightMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? _panel : _lightPanel,
      borderRadius: BorderRadius.circular(10),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 14,
      color: isDark ? _line : _lightBorder,
    );
  }
}
