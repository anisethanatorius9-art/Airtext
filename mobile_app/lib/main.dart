import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

String _newCallRoom() {
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = math.Random.secure();
  final suffix = List.generate(
    20,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
  return 'airtext-$suffix';
}

String _callRoomUrl(String room) =>
    Uri.https('meet.jit.si', '/$room').toString();

Future<bool> _confirmMeetingStart(
  BuildContext context, {
  required String title,
  required String room,
}) async {
  final url = _callRoomUrl(room);
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share this code or link so others can join:'),
              const SizedBox(height: 12),
              SelectableText(room),
              const SizedBox(height: 6),
              SelectableText(url, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Meeting link copied.')),
                  );
                }
              },
              child: const Text('Copy link'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.video_call_outlined),
              label: const Text('Start call'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> _joinCallRoom(
  BuildContext context, {
  required String room,
  required String displayName,
}) async {
  try {
    final response = await JitsiMeet().join(
      JitsiMeetConferenceOptions(
        serverURL: 'https://meet.jit.si',
        room: room,
        userInfo: JitsiMeetUserInfo(displayName: displayName),
        configOverrides: const {
          'prejoinPageEnabled': true,
          'startWithAudioMuted': false,
          'startWithVideoMuted': false,
        },
        featureFlags: const {
          FeatureFlags.addPeopleEnabled: true,
          FeatureFlags.inviteEnabled: true,
          FeatureFlags.chatEnabled: true,
        },
      ),
    );
    if (!response.isSuccess && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Could not join the call.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start the call: $error')),
      );
    }
  }
}

enum AirTextLogoStyle { mark, monogram, signal }

class AirTextAppearance extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  AirTextLogoStyle logoStyle = AirTextLogoStyle.mark;
  Color chatAccent = _mint;
  Uint8List? chatWallpaper;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
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
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('airtext.appearance.theme', value.name);
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

  Future<ChatMessage> sendMessage(int conversationId, String body) async {
    final response = await _request(
      'POST',
      '/conversations/$conversationId/messages',
      body: {'body': body},
    );
    return ChatMessage.fromApi(response['data'] as Map<String, dynamic>);
  }

  Future<void> markConversationRead(int conversationId) async {
    await _request('POST', '/conversations/$conversationId/read');
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

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final uri = _baseUri.replace(path: '${_baseUri.path}$path');
    final headers = <String, String>{
      'Accept': 'application/json',
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
                : 'AirText request failed (${response.statusCode}).');
        throw AirTextApiException(message, response.statusCode);
      }
      return decoded;
    } on AirTextApiException {
      rethrow;
    } on http.ClientException {
      throw const AirTextApiException(
        'Could not reach AirText. Check the server address and connection.',
        0,
      );
    } on FormatException {
      throw const AirTextApiException(
        'The AirText server returned invalid data.',
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
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: _appearance.themeMode,
        builder: (context, child) {
          final brightness = Theme.of(context).brightness;
          return CupertinoTheme(
            data: CupertinoThemeData(
              brightness: brightness,
              primaryColor: _appearance.chatAccent,
              scaffoldBackgroundColor: brightness == Brightness.dark
                  ? _obsidian
                  : _paper,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: ChatsPage(
          api: widget.api ?? AirTextApi(),
          appearance: _appearance,
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      platform: TargetPlatform.iOS,
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: isDark ? _mint : _green,
        brightness: brightness,
        surface: isDark ? _obsidian : _lightPanel,
      ),
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
        AirTextLogoStyle.mark => CustomPaint(
          size: Size.square(size),
          painter: const _AirTextMarkPainter(),
        ),
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

class _AirTextMarkPainter extends CustomPainter {
  const _AirTextMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 38, size.height / 38);

    final bubblePaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 7, 26, 20),
        const Radius.circular(5),
      ),
      bubblePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(10, 24)
        ..lineTo(8, 32)
        ..lineTo(18, 26)
        ..close(),
      bubblePaint,
    );

    final inkPaint = Paint()
      ..color = const Color(0xFF123B50)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(12, 13), const Offset(26, 13), inkPaint);
    canvas.drawLine(const Offset(12, 19), const Offset(21, 19), inkPaint);

    final signalPaint = Paint()
      ..color = const Color(0xFFFFBE55)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(20, 25)
        ..lineTo(23, 22)
        ..lineTo(26, 25)
        ..lineTo(30, 20),
      signalPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChatMessage {
  ChatMessage(
    this.text,
    this.time, {
    this.isMine = false,
    this.expiresAt,
    this.reaction,
    this.status = 'sent',
  });

  final String text;
  final String time;
  final bool isMine;
  final DateTime? expiresAt;
  String? reaction;
  String status;

  factory ChatMessage.fromApi(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['sent_at'] as String? ?? '');
    return ChatMessage(
      json['body'] as String? ?? '',
      timestamp == null ? 'Now' : _formatMessageTime(timestamp.toLocal()),
      isMine: json['is_mine'] as bool? ?? false,
      status: json['status'] as String? ?? 'sent',
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
  });

  final String name;
  final String initials;
  final String status;
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
  final String? recipientEmail;
  final bool isSmsRoute;

  String get preview => messages.isEmpty ? '' : messages.last.text;

  factory ChatConversation.fromApi(Map<String, dynamic> json) {
    final messages = (json['messages'] as List<dynamic>? ?? [])
        .map((item) => ChatMessage.fromApi(item as Map<String, dynamic>))
        .toList();
    final name = json['name'] as String? ?? 'Air app contact';
    final isSms = json['route'] == 'sms';
    return ChatConversation(
      name: name,
      initials: name
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .take(2)
          .map((part) => part[0].toUpperCase())
          .join(),
      status: isSms ? 'SMS contact' : 'Air app contact',
      time: messages.isEmpty ? 'New' : messages.last.time,
      unread: json['unread_count'] as int? ?? 0,
      color: const Color(0xFF26372F),
      messages: messages,
      phoneNumber: json['phone_number'] as String? ?? '',
      backendId: json['id'] as int?,
      recipientEmail: json['email'] as String?,
      isSmsRoute: isSms,
    );
  }
}

String _formatMessageTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
}

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key, required this.api, required this.appearance});

  final AirTextApi api;
  final AirTextAppearance appearance;

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final _searchController = TextEditingController();
  late final AirTextApi _api = widget.api;
  Timer? _conversationSyncTimer;
  final List<ChatConversation> _conversations = [
    ChatConversation(
      name: 'Mariam Hassan',
      initials: 'MH',
      status: 'AirText contact',
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
  String _username = '@airtextuser';
  String _about = 'Available';
  Uint8List? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadSavedContacts();
    _loadSavedProfile();
    _restoreRemoteSession();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _conversationSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreRemoteSession() async {
    await _api.restoreToken();
    if (!_api.isAuthenticated) return;
    try {
      final user = await _api.getCurrentUser();
      await _loadRemoteConversations();
      if (!mounted) return;
      setState(() {
        _displayName = user['name'] as String? ?? _displayName;
        _username = user['email'] as String? ?? _username;
      });
      _startConversationSync();
    } on AirTextApiException catch (error) {
      if (error.statusCode == 401) await _api.clearToken();
    }
  }

  Future<void> _loadRemoteConversations() async {
    final conversations = await _api.getConversations();
    if (!mounted) return;
    setState(() {
      _conversations
        ..clear()
        ..addAll(conversations);
    });
  }

  void _startConversationSync() {
    _conversationSyncTimer?.cancel();
    _conversationSyncTimer = Timer.periodic(const Duration(seconds: 15), (
      _,
    ) async {
      try {
        await _loadRemoteConversations();
      } on AirTextApiException catch (error) {
        if (error.statusCode == 401) {
          _conversationSyncTimer?.cancel();
          await _api.clearToken();
        }
      }
    });
  }

  Future<void> _onApiAuthenticated(Map<String, dynamic> user) async {
    await _loadRemoteConversations();
    if (!mounted) return;
    setState(() {
      _displayName = user['name'] as String? ?? _displayName;
      _username = user['email'] as String? ?? _username;
    });
    _startConversationSync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _buildChats(),
            const _UpdatesPage(),
            const _AirTextShopPage(),
            _SettingsPage(
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
              onSave: _saveProfile,
              onOpenAccount: _openAccount,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _FloatingNavigationDock(
        selectedIndex: _selectedTab,
        onSelected: (index) => setState(() => _selectedTab = index),
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
                    'Chats',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'New conversation',
                  onPressed: _startNewConversation,
                  icon: Icon(Icons.add, color: mutedColor),
                ),
                IconButton(
                  tooltip: _commandExpanded
                      ? 'Close command sphere'
                      : 'Open command sphere',
                  onPressed: () =>
                      setState(() => _commandExpanded = !_commandExpanded),
                  icon: Icon(
                    _commandExpanded ? Icons.close_rounded : Icons.hub_outlined,
                    color: mutedColor,
                  ),
                ),
                IconButton(
                  tooltip: 'More options',
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
                hintText: 'Search or start a new chat',
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
                          label: 'New message',
                          onTap: _startNewConversation,
                        ),
                        const SizedBox(width: 8),
                        _NexusAction(
                          icon: CupertinoIcons.person_2,
                          label: 'Contacts',
                          onTap: _openContacts,
                        ),
                        const SizedBox(width: 8),
                        _NexusAction(
                          icon: CupertinoIcons.phone,
                          label: 'Calls',
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
                      label: Text(filter),
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
                      'No chats found',
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
          onMessageSent: () => setState(() {}),
        ),
      ),
    );
  }

  Future<void> _openAppearance() async {
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

    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final details = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New conversation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'AirText account email',
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('or'),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'SMS number (+country code)',
                ),
              ),
              TextField(
                controller: nameController,
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
              'email': emailController.text.trim(),
              'phone': phoneController.text.trim(),
              'name': nameController.text.trim(),
            }),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    emailController.dispose();
    phoneController.dispose();
    nameController.dispose();
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
          onAuthenticated: _onApiAuthenticated,
          onSignOut: _signOutLocally,
          onDeleteLocalData: _deleteLocalData,
        ),
      ),
    );
  }

  Future<void> _signOutLocally() async {
    try {
      await _api.logout();
    } on AirTextApiException {
      await _api.clearToken();
    }
    _conversationSyncTimer?.cancel();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('airtext.profile');
    if (!mounted) return;
    setState(() {
      _displayName = 'Air app User';
      _username = '@airtextuser';
      _about = 'Available';
      _profileImage = null;
      _selectedTab = 0;
      _conversations
        ..clear()
        ..addAll(_offlineConversations);
    });
    Navigator.of(context).pop();
  }

  Future<void> _deleteLocalData() async {
    try {
      await _api.logout();
    } on AirTextApiException {
      await _api.clearToken();
    }
    _conversationSyncTimer?.cancel();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('airtext.profile');
    await preferences.remove('airtext.contacts');
    if (!mounted) return;
    setState(() {
      _contacts = [];
      _displayName = 'Air app User';
      _username = '@airtextuser';
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
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => _ContactsPage(
          contacts: _contacts,
          onContactSaved: (contact) {
            setState(() => _contacts = [..._contacts, contact]);
            _saveContacts();
          },
          onOpenChat: (contact) {
            final existing = _conversations
                .cast<ChatConversation?>()
                .firstWhere(
                  (conversation) =>
                      conversation?.phoneNumber == contact.phoneNumber,
                  orElse: () => null,
                );
            final conversation =
                existing ??
                ChatConversation(
                  name: contact.name,
                  initials: contact.initials,
                  status: contact.isAirTextUser
                      ? 'Air app contact'
                      : 'SMS contact',
                  time: 'New',
                  unread: 0,
                  color: const Color(0xFFDCE8F8),
                  phoneNumber: contact.phoneNumber,
                  messages: [],
                );
            if (existing == null) {
              _conversations.add(conversation);
            }
            Navigator.of(context).pop();
            _openConversation(conversation);
          },
        ),
      ),
    );
  }

  Future<void> _openCalls() async {
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => _CallsPage(displayName: _displayName),
      ),
    );
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
          const Padding(
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
                'Device linking needs an authenticated AirText account service.',
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

class AirTextContact {
  const AirTextContact({
    required this.name,
    required this.phoneNumber,
    required this.isAirTextUser,
  });

  final String name;
  final String phoneNumber;
  final bool isAirTextUser;

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
  };

  factory AirTextContact.fromJson(Map<String, dynamic> json) => AirTextContact(
    name: json['name'] as String,
    phoneNumber: json['phoneNumber'] as String,
    isAirTextUser: json['isAirTextUser'] as bool? ?? false,
  );
}

class _ContactsPage extends StatefulWidget {
  const _ContactsPage({
    required this.contacts,
    required this.onContactSaved,
    required this.onOpenChat,
  });

  final List<AirTextContact> contacts;
  final ValueChanged<AirTextContact> onContactSaved;
  final ValueChanged<AirTextContact> onOpenChat;

  @override
  State<_ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<_ContactsPage> {
  final _searchController = TextEditingController();
  String _filter = 'All';

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

  Future<void> _addContact() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final contact = await showCupertinoDialog<AirTextContact>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('New contact'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(controller: nameController, placeholder: 'Name'),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: phoneController,
              placeholder: '+255712345678',
              keyboardType: TextInputType.phone,
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
              final phone = phoneController.text.trim();
              if (name.isEmpty ||
                  phone.replaceAll(RegExp(r'\D'), '').length < 7) {
                return;
              }
              Navigator.pop(
                context,
                AirTextContact(
                  name: name,
                  phoneNumber: phone,
                  isAirTextUser: false,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    phoneController.dispose();
    if (contact == null || !mounted) return;
    widget.onContactSaved(contact);
  }

  Future<void> _invite(AirTextContact contact) async {
    final uri = Uri(
      scheme: 'sms',
      path: contact.phoneNumber.replaceAll(RegExp(r'\s+'), ''),
      queryParameters: {'body': 'Join me on AirText.'},
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

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAirTextRoute = conversation.status == 'Air app contact';
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
    required this.onMessageSent,
    super.key,
  });

  final ChatConversation conversation;
  final AirTextApi api;
  final AirTextAppearance appearance;
  final String displayName;
  final VoidCallback onMessageSent;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _messageController = TextEditingController();
  Timer? _expiryTimer;
  Timer? _syncTimer;
  bool _showEmojiPicker = false;
  late String _disappearingDuration;
  late bool _blocked;
  late bool _reported;
  late bool _shareLastSeen;
  late bool _readReceipts;

  @override
  void initState() {
    super.initState();
    _disappearingDuration = widget.conversation.disappearingDuration;
    _blocked = widget.conversation.isBlocked;
    _reported = widget.conversation.isReported;
    _shareLastSeen = widget.conversation.shareLastSeen;
    _readReceipts = widget.conversation.readReceipts;
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
      _markConversationRead();
      _syncTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _syncRemoteConversation(),
      );
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _syncTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markConversationRead() async {
    final backendId = widget.conversation.backendId;
    if (backendId == null) return;

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

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAirTextRoute = conversation.status == 'Air app contact';
    final canvasColor = isDark ? _obsidian : _paper;
    final panelColor = isDark ? _panel : _lightPanel;
    final borderColor = isDark ? _line : _lightBorder;
    final primaryText = isDark ? Colors.white : _ink;
    final mutedText = isDark ? _silver : _lightMuted;
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
                    conversation.status,
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
                  isAirTextRoute ? 'AIRTEXT' : 'SMS',
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
                itemCount: conversation.messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Center(
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
                          'Today',
                          style: TextStyle(color: mutedText, fontSize: 11),
                        ),
                      ),
                    );
                  }
                  return _MessageBubble(
                    message: conversation.messages[index - 1],
                    isAirTextRoute: isAirTextRoute,
                    accentColor: widget.appearance.chatAccent,
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
                        onChanged: (_) => setState(() {}),
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
                              message: 'Record voice message',
                              child: CupertinoButton(
                                key: const ValueKey('voice'),
                                padding: const EdgeInsets.all(8),
                                minimumSize: Size.zero,
                                onPressed: _showVoiceUnavailable,
                                child: Icon(
                                  CupertinoIcons.mic_fill,
                                  color: widget.appearance.chatAccent,
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _blocked) return;

    final backendId = widget.conversation.backendId;
    if (widget.api.isAuthenticated && backendId != null) {
      try {
        final message = await widget.api.sendMessage(backendId, text);
        if (!mounted) return;
        setState(() {
          widget.conversation.messages.add(message);
          _messageController.clear();
          _showEmojiPicker = false;
        });
        widget.onMessageSent();
      } on AirTextApiException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
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
          expiresAt: duration == null ? null : DateTime.now().add(duration),
        ),
      );
      _messageController.clear();
    });
    setState(() => _showEmojiPicker = false);
    widget.onMessageSent();
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
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => _PhoneCallPage(
          contactName: widget.conversation.name,
          phoneNumber: number,
        ),
      ),
    );
  }

  Future<void> _startVideoCall() async {
    final room = _newCallRoom();
    final confirmed = await _confirmMeetingStart(
      context,
      title: 'Video call with ${widget.conversation.name}',
      room: room,
    );
    if (!confirmed || !mounted) return;
    await _joinCallRoom(context, room: room, displayName: widget.displayName);
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
          'The AirText message API currently accepts text messages only.',
        );
      case 'location':
        await _showUnavailableFeature(
          'Location sharing',
          'Location sharing is not connected to the AirText message API yet.',
        );
      case 'contact':
        await _showUnavailableFeature(
          'Contact sharing',
          'Contact cards are not connected to the AirText message API yet.',
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
      'Media upload is not connected to the AirText message API yet.',
    );
  }

  Future<void> _showVoiceUnavailable() => _showUnavailableFeature(
    'Voice messages',
    'Voice recording and audio upload are not connected to the AirText message API yet.',
  );

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
        onReadReceiptsChanged: (value) => setState(() {
          _readReceipts = value;
          widget.conversation.readReceipts = value;
        }),
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
  static const _products = [
    _ShopProductData(
      id: 'credits-5000',
      category: 'credits',
      icon: Icons.inventory_2_outlined,
      eyebrow: '5,000 BULK SMS',
      name: 'SMS Credits Package',
      description: 'High-throughput local GSM routes for campaigns and alerts.',
      price: 'TZS 50,000',
      action: 'Buy package',
    ),
    _ShopProductData(
      id: 'gemini-bot',
      category: 'bots',
      icon: Icons.smart_toy_outlined,
      eyebrow: 'GEMINI AI BOT',
      name: 'AI Auto-Responder Bot',
      description: 'Automated SMS customer support that replies around the clock.',
      price: 'TZS 15,000 / month',
      action: 'Install bot',
    ),
    _ShopProductData(
      id: 'sender-id',
      category: 'gateways',
      icon: Icons.sell_outlined,
      eyebrow: 'BRANDED SENDER ID',
      name: 'Custom Sender ID',
      description: 'Register a trusted business name for outgoing messages.',
      price: 'TZS 30,000 / year',
      action: 'Request ID',
    ),
    _ShopProductData(
      id: 'tourism-bot',
      category: 'bots',
      icon: Icons.auto_awesome_outlined,
      eyebrow: 'READY TO DEPLOY',
      name: 'Tourism Concierge Bot',
      description: 'Answer booking and itinerary questions automatically.',
      price: 'TZS 12,000 / month',
      action: 'Install bot',
    ),
    _ShopProductData(
      id: 'order-template',
      category: 'templates',
      icon: Icons.description_outlined,
      eyebrow: 'MESSAGE TEMPLATE',
      name: 'Order Updates Pack',
      description: 'Prebuilt delivery, payment, and order notification flows.',
      price: 'TZS 8,000 one-time',
      action: 'Get template',
    ),
    _ShopProductData(
      id: 'gsm-node',
      category: 'gateways',
      icon: Icons.router_outlined,
      eyebrow: '99.9% UPTIME',
      name: 'Dedicated GSM Gateway Node',
      description: 'A dedicated route for business-critical SMS traffic.',
      price: 'TZS 45,000 / month',
      action: 'Activate node',
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
                        'AirText Shop',
                        style: TextStyle(
                          color: text,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Marketplace',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Payments are not connected',
                  onPressed: _topUpCredits,
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
                      'Wallet',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  Text(
                    'Not connected',
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
                hintText: 'Search products and services',
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
              segments: const [
                ButtonSegment(value: 'browse', label: Text('Browse')),
                ButtonSegment(value: 'installed', label: Text('Installed')),
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
                        label: Text(category.label),
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
        child: Text('No products found', style: TextStyle(color: muted)),
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
        child: Text('No installed services', style: TextStyle(color: muted)),
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

  void _topUpCredits() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payments are not configured. No credits were added.'),
      ),
    );
  }

  void _selectProduct(_ShopProductData product) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payments are not configured. No purchase was made.'),
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
    this.missed = false,
  });

  final String name;
  final String number;
  final String time;
  final String direction;
  final bool missed;
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
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _CallPattern()),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        color: Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        tooltip: 'Close call screen',
                      ),
                      const Spacer(),
                      const Icon(Icons.lock_outline, color: Colors.white70, size: 15),
                      const SizedBox(width: 6),
                      const Text(
                        'AIRTEXT CALL',
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
                  style: const TextStyle(color: Color(0xFFAAB8BE), fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ready to call',
                  style: TextStyle(color: Color(0xFFAAB8BE), fontSize: 13),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141D21),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: const Color(0xFF26343A)),
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
                            onTap: () => setState(() => _speakerOn = !_speakerOn),
                          ),
                          _CallControl(
                            icon: Icons.videocam_rounded,
                            label: 'Video',
                            selected: _videoOn,
                            onTap: () => setState(() => _videoOn = !_videoOn),
                          ),
                          _CallControl(
                            icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                            label: 'Mute',
                            selected: _muted,
                            onTap: () => setState(() => _muted = !_muted),
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
        ],
      ),
    );
  }

  Future<void> _startPhoneCall() async {
    final phone = widget.phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: phone);
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone app is available.')),
      );
    }
  }

  Future<void> _shareNumber() async {
    await Clipboard.setData(ClipboardData(text: widget.phoneNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Number copied.')),
    );
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
    final background = color ??
        (selected ? Colors.white : const Color(0xFF202A2F));
    final iconColor = foreground ??
        (selected ? const Color(0xFF101714) : Colors.white);
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
        canvas.drawLine(
          Offset(x + 23, y + 12),
          Offset(x + 31, y + 20),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CallPattern oldDelegate) => false;
}

class _CallsPage extends StatefulWidget {
  const _CallsPage({required this.displayName});

  final String displayName;

  @override
  State<_CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<_CallsPage> {
  final _numberController = TextEditingController();
  final _roomController = TextEditingController();
  final List<_CallEntry> _history = [
    const _CallEntry(
      name: 'Mariam Hassan',
      number: '+255 718 220 901',
      time: 'Today, 10:42 AM',
      direction: 'Outgoing',
    ),
    const _CallEntry(
      name: 'Juma K.',
      number: '+255 712 884 102',
      time: 'Yesterday, 8:15 PM',
      direction: 'Incoming',
    ),
    const _CallEntry(
      name: 'Unknown number',
      number: '+255 782 328 215',
      time: 'Mon, 4:20 PM',
      direction: 'Missed',
      missed: true,
    ),
  ];

  @override
  void dispose() {
    _numberController.dispose();
    _roomController.dispose();
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
                title: const Text('Start a video or group call'),
                subtitle: const Text('Create a room and invite others'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _startGroupCall,
              ),
              const _GroupDivider(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _roomController,
                        placeholder: 'Meeting link or room code',
                        textInputAction: TextInputAction.go,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _joinMeeting(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Join video call',
                      onPressed: _roomController.text.trim().isEmpty
                          ? null
                          : _joinMeeting,
                      icon: const Icon(Icons.video_call_outlined),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ListSectionLabel('RECENT CALLS'),
          _GroupedList(
            children: [
              for (var index = 0; index < _history.length; index++) ...[
                if (index > 0) const _GroupDivider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _history[index].missed
                        ? const Color(0xFFFFE7E5)
                        : const Color(0xFFE5EFFF),
                    foregroundColor: _history[index].missed
                        ? const Color(0xFFFF3B30)
                        : _green,
                    child: Icon(
                      _history[index].missed
                          ? CupertinoIcons.phone_down
                          : CupertinoIcons.phone,
                    ),
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
            'Phone calls use your device dialer. Video and group calls use Jitsi Meet and require an internet connection.',
            style: TextStyle(color: Color(0xFF6D6D72), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _startGroupCall() async {
    final room = _newCallRoom();
    final confirmed = await _confirmMeetingStart(
      context,
      title: 'Start a video or group call',
      room: room,
    );
    if (!confirmed || !mounted) return;
    await _joinCallRoom(context, room: room, displayName: widget.displayName);
  }

  Future<void> _joinMeeting() async {
    final entered = _roomController.text.trim();
    if (entered.isEmpty) return;
    final uri = Uri.tryParse(
      entered.startsWith('http') ? entered : 'https://meet.jit.si/$entered',
    );
    final room = (uri?.pathSegments.lastOrNull ?? entered).replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '',
    );
    if (room.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid meeting link or room code.'),
        ),
      );
      return;
    }
    _roomController.clear();
    setState(() {});
    await _joinCallRoom(context, room: room, displayName: widget.displayName);
  }

  Future<void> _call(String name, String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9+*#]'), '');
    if (cleanNumber.replaceAll(RegExp(r'\D'), '').length < 7) return;
    setState(() {
      _history.insert(
        0,
        _CallEntry(
          name: name,
          number: number,
          time: 'Just now',
          direction: 'Outgoing',
        ),
      );
      _numberController.clear();
    });
    await Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (_) => _PhoneCallPage(
          contactName: name,
          phoneNumber: cleanNumber,
        ),
      ),
    );
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
    required this.isAirTextRoute,
    required this.accentColor,
  });

  final ChatMessage message;
  final bool isAirTextRoute;
  final Color accentColor;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isFailed = message.status == 'failed';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark
        ? (message.isMine ? const Color(0xFF155B46) : _panel)
        : (message.isMine ? const Color(0xFFD9FDD3) : _lightPanel);
    final messageTextColor = isDark ? _nexusText : _ink;
    final mutedTextColor = isDark ? _silver : _lightMuted;
    final routeColor = isFailed
        ? const Color(0xFFB3261E)
        : widget.isAirTextRoute
        ? (isDark ? widget.accentColor : _green)
        : (isDark ? const Color(0xFFD9B77A) : const Color(0xFF805A18));
    final routeLabel = isFailed
        ? '${widget.isAirTextRoute ? 'AIRTEXT' : 'SMS'} · FAILED'
        : widget.isAirTextRoute
        ? 'AIRTEXT'
        : 'SMS';
    return Column(
      crossAxisAlignment: message.isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: _chooseReaction,
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
                    Text(
                      message.text,
                      style: TextStyle(
                        color: messageTextColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
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
                        if (message.isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all,
                            size: 13,
                            color: isDark ? _mint : _green,
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
    (label: 'Nexus', icon: CupertinoIcons.chat_bubble_2),
    (label: 'Mesh', icon: CupertinoIcons.circle_grid_3x3),
    (label: 'Shop', icon: CupertinoIcons.bag),
    (label: 'Vault', icon: CupertinoIcons.settings),
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
                    label: _destinations[index].label,
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
    this.imageBytes,
  });

  final String name;
  final String initials;
  final String time;
  final Color color;
  final String message;
  final bool isMine;
  final Uint8List? imageBytes;
  int views = 0;
  int likes = 0;
  bool likedByMe = false;
  final List<String> comments = [];
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
  const _UpdatesPage();

  @override
  State<_UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<_UpdatesPage> {
  _StatusUpdate? _myStatus;
  final List<_StatusUpdate> _recentStatuses = [
    _StatusUpdate(
      name: 'Mariam Hassan',
      initials: 'MH',
      time: 'Today, 10:42 AM',
      color: const Color(0xFFD6E9DE),
      message: 'Asubuhi nzuri kutoka mjini!',
    ),
    _StatusUpdate(
      name: 'Juma K.',
      initials: 'JK',
      time: 'Yesterday, 8:15 PM',
      color: const Color(0xFFF5DFCC),
      message: 'Safari njema, tutaonana kesho.',
    ),
  ];
  final List<_Community> _communities = [
    _Community(
      'AirText Community',
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Status',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Communities',
                onPressed: _openCommunities,
                icon: const Icon(CupertinoIcons.person_3, color: _green),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              const _ListSectionLabel('MY STATUS'),
              _GroupedList(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    leading: _MyStatusAvatar(
                      hasStatus: _myStatus != null,
                      imageBytes: _myStatus?.imageBytes,
                    ),
                    title: const Text(
                      'My Status',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _myStatus == null
                          ? 'Tap to add status update'
                          : '${_myStatus!.message} · ${_myStatus!.views} views · ${_myStatus!.likes} likes',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF75827D),
                        fontSize: 12,
                      ),
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
              const _ListSectionLabel('RECENT UPDATES'),
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
                      time:
                          '${_recentStatuses[index].time} · ${_recentStatuses[index].likes} likes',
                      color: _recentStatuses[index].color,
                      message: _recentStatuses[index].message,
                      onTap: () => _openStatus(_recentStatuses[index]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: _ListSectionLabel('COMMUNITIES')),
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
            onPressed: () => Navigator.pop(context, 'photo'),
            child: const Text('Choose a photo'),
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
    if (choice == 'photo') await _pickPhotoStatus();
  }

  Future<void> _addTextStatus() async {
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
    setState(() {
      _myStatus = _StatusUpdate(
        name: 'You',
        initials: 'A',
        time: 'Just now',
        color: const Color(0xFFE5EFFF),
        message: status,
        isMine: true,
      );
    });
  }

  Future<void> _pickPhotoStatus() async {
    final photo = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!mounted) return;
    setState(() {
      _myStatus = _StatusUpdate(
        name: 'You',
        initials: 'A',
        time: 'Just now',
        color: const Color(0xFFE5EFFF),
        message: 'Photo status',
        isMine: true,
        imageBytes: bytes,
      );
    });
  }

  void _openStatus(_StatusUpdate status) {
    if (!status.isMine) status.views++;
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) =>
            _StatusViewerPage(status: status, onChanged: () => setState(() {})),
      ),
    );
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
  });

  final String initials;
  final String name;
  final String time;
  final Color color;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _green, width: 2),
        ),
        child: CircleAvatar(
          radius: 23,
          backgroundColor: color,
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

class _MyStatusAvatar extends StatelessWidget {
  const _MyStatusAvatar({required this.hasStatus, this.imageBytes});

  final bool hasStatus;
  final Uint8List? imageBytes;

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
            backgroundImage: imageBytes == null
                ? null
                : MemoryImage(imageBytes!),
            child: imageBytes == null
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
  const _StatusViewerPage({required this.status, required this.onChanged});

  final _StatusUpdate status;
  final VoidCallback onChanged;

  @override
  State<_StatusViewerPage> createState() => _StatusViewerPageState();
}

class _StatusViewerPageState extends State<_StatusViewerPage> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    return Scaffold(
      appBar: AppBar(
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
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF123B50),
              alignment: Alignment.center,
              child: status.imageBytes == null
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
                  : Image.memory(status.imageBytes!, fit: BoxFit.contain),
            ),
          ),
          if (status.isMine) _buildInsights(status),
          if (status.comments.isNotEmpty)
            SizedBox(
              height: 96,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: status.comments.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    status.comments[index],
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  if (!status.isMine)
                    IconButton(
                      tooltip: status.likedByMe
                          ? 'Unlike status'
                          : 'Like status',
                      onPressed: _toggleLike,
                      icon: Icon(
                        status.likedByMe
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        color: status.likedByMe
                            ? const Color(0xFFFF3B62)
                            : _green,
                      ),
                    ),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _commentController,
                      placeholder: 'Comment on status',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send comment',
                    onPressed: _sendComment,
                    icon: const Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      color: _green,
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status insights',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(CupertinoIcons.eye, size: 18, color: _green),
              const SizedBox(width: 6),
              Text('${status.views} views'),
              const SizedBox(width: 20),
              const Icon(
                CupertinoIcons.heart_fill,
                size: 17,
                color: Color(0xFFFF3B62),
              ),
              const SizedBox(width: 6),
              Text('${status.likes} likes'),
            ],
          ),
          if (status.views == 0)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Viewers will appear here when status activity is connected.',
                style: TextStyle(fontSize: 11, color: Color(0xFF77777D)),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleLike() {
    setState(() {
      widget.status.likedByMe = !widget.status.likedByMe;
      widget.status.likes += widget.status.likedByMe ? 1 : -1;
    });
    widget.onChanged();
  }

  void _sendComment() {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;
    setState(() {
      widget.status.comments.add(comment);
      _commentController.clear();
    });
    widget.onChanged();
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
    required this.onSave,
    required this.onOpenAccount,
  });

  final String displayName;
  final String username;
  final String about;
  final Uint8List? imageBytes;
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
                            ? null
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
    await widget.onSave(
      name,
      username.startsWith('@') ? username : '@$username',
      _aboutController.text.trim(),
      _imageBytes,
    );
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
    required this.onAuthenticated,
    required this.onSignOut,
    required this.onDeleteLocalData,
  });

  final AirTextApi api;
  final Future<void> Function(Map<String, dynamic> user) onAuthenticated;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteLocalData;

  @override
  State<_AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<_AccountPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeRequested = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          const _ListSectionLabel('SIGN IN WITH EMAIL'),
          _GroupedList(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: CupertinoTextField(
                  controller: _emailController,
                  enabled: !_isSubmitting,
                  placeholder: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.mail, size: 18),
                  ),
                ),
              ),
              if (_codeRequested) ...[
                const _GroupDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: CupertinoTextField(
                    controller: _codeController,
                    enabled: !_isSubmitting,
                    placeholder: '6-digit email code',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(CupertinoIcons.lock, size: 18),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _codeRequested
                ? 'Enter the one-time code sent to your email. It expires after 10 minutes.'
                : 'A one-time code will be sent to this email. No password is stored on this device.',
            style: TextStyle(
              color: Color(0xFF6D6D72),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _isSubmitting
                ? null
                : _codeRequested
                ? _verifyOtp
                : _requestOtp,
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _codeRequested
                        ? CupertinoIcons.checkmark_shield
                        : CupertinoIcons.paperplane,
                  ),
            label: Text(_codeRequested ? 'Verify and sign in' : 'Send code'),
          ),
          const SizedBox(height: 24),
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
                  'Sign out of AirText and clear this device profile',
                ),
                onTap: () => _confirmAction(
                  title: 'Sign out?',
                  message: 'Your AirText session and local profile will be cleared from this device.',
                  action: 'Sign out',
                  onConfirm: widget.onSignOut,
                ),
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
                  message: 'This removes the profile and saved contacts from this device, not the AirText account.',
                  action: 'Delete',
                  onConfirm: widget.onDeleteLocalData,
                  destructive: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email address.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.api.requestOtp(email);
      if (!mounted) return;
      setState(() => _codeRequested = true);
      _showMessage('If the address is valid, a sign-in code has been sent.');
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
      final user = await widget.api.verifyOtp(email: email, code: code);
      await widget.onAuthenticated(user);
      if (mounted) Navigator.of(context).pop();
    } on AirTextApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
}

class _ChatThemePage extends StatelessWidget {
  const _ChatThemePage({required this.appearance});

  final AirTextAppearance appearance;

  static const _swatches = [
    (name: 'AirText Mint', color: Color(0xFF9BE2BD)),
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
    required this.appearance,
    required this.onOpenProfile,
    required this.onOpenAccount,
    required this.onOpenAppearance,
  });

  final AirTextAppearance appearance;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenAppearance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Text(
            'Settings',
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
              const _ListSectionLabel('ACCOUNT'),
              _GroupedList(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    subtitle: 'Photo, username and about',
                    onTap: onOpenProfile,
                  ),
                  const _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Account',
                    subtitle: 'Registration, sign out and data',
                    onTap: onOpenAccount,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _ListSectionLabel('DISPLAY'),
              _GroupedList(
                children: [
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: '${appearance.themeMode.name} · Chat Theme',
                    onTap: onOpenAppearance,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _ListSectionLabel('MESSAGING'),
              _GroupedList(
                children: [
                  _SettingsTile(
                    icon: Icons.sms_outlined,
                    title: 'GSM & SMS Protocol',
                    subtitle: 'Manage offline messaging',
                    onTap: () => _openSettings(context, 'GSM & SMS Protocol'),
                  ),
                  const _GroupDivider(),
                  _SettingsTile(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    subtitle: 'Message & call tones',
                    onTap: () => _openSettings(context, 'Notifications'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _ListSectionLabel('MORE'),
              _GroupedList(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'Help & About AirText',
                    subtitle: 'Payload protocol updates',
                    onTap: () => _openSettings(context, 'Help & About AirText'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openSettings(BuildContext context, String section) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _SettingsDetailPage(section: section),
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
  const _SettingsDetailPage({required this.section});

  final String section;

  @override
  State<_SettingsDetailPage> createState() => _SettingsDetailPageState();
}

class _SettingsDetailPageState extends State<_SettingsDetailPage> {
  bool _offlineMessaging = true;
  bool _messageSounds = true;
  bool _callSounds = true;
  bool _twoStepVerification = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(section),
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
            const _ListSectionLabel('OFFLINE MESSAGING'),
            _GroupedList(
              children: [
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('SMS fallback'),
                  subtitle: const Text(
                    'Send messages over GSM when data is unavailable',
                  ),
                  value: _offlineMessaging,
                  onChanged: (value) =>
                      setState(() => _offlineMessaging = value),
                ),
                const _GroupDivider(),
                const ListTile(
                  title: Text('Payload protocol'),
                  subtitle: Text('AirText protocol v1.0'),
                  trailing: Icon(Icons.chevron_right),
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
                  value: _messageSounds,
                  onChanged: (value) => setState(() => _messageSounds = value),
                ),
                const _GroupDivider(),
                SwitchListTile.adaptive(
                  activeThumbColor: _green,
                  title: const Text('Call sounds'),
                  value: _callSounds,
                  onChanged: (value) => setState(() => _callSounds = value),
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
}

class _ListSectionLabel extends StatelessWidget {
  const _ListSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF75827D),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 64,
      endIndent: 14,
      color: Color(0xFFE8ECE7),
    );
  }
}
