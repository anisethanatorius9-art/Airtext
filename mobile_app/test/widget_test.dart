// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_app/main.dart';
import 'package:mobile_app/video_call_screen.dart';

class _MemoryApiTokenStore implements ApiTokenStore {
  _MemoryApiTokenStore([this.token]);

  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

AirTextApi _testApi({
  bool requirePhoneVerification = false,
  bool authenticated = true,
  bool includeRemoteConversation = false,
}) => AirTextApi(
  baseUrl: 'https://airtext.test/api',
  tokenStore: _MemoryApiTokenStore(authenticated ? 'test-token' : null),
  client: MockClient((request) async {
    if (request.url.path.endsWith('/me')) {
      return http.Response(
        '{"id":1,"name":"Asha Mushi","email":"asha@example.com","phone_number":"+255712345678","phone_verified_at":"2026-10-01T00:00:00Z"}',
        200,
      );
    }
    if (request.url.path.endsWith('/auth/otp/request')) {
      return http.Response('{"message":"Code sent."}', 202);
    }
    if (request.url.path.endsWith('/auth/otp/verify')) {
      if (requirePhoneVerification) {
        return http.Response(
          '{"requires_phone_verification":true,"challenge":"${'a' * 64}","phone_hint":"****5678","user":{"id":1,"name":"Asha Mushi","email":"asha@example.com"}}',
          200,
        );
      }
      return http.Response(
        '{"token":"test-token","user":{"id":1,"name":"Asha Mushi","email":"asha@example.com"}}',
        200,
      );
    }
    if (request.url.path.endsWith('/me/profile')) {
      return http.Response(
        '{"user":{"id":1,"name":"Asha Mushi","email":"asha@example.com"}}',
        200,
      );
    }
    if (request.url.path.endsWith('/auth/phone/otp/verify-login')) {
      return http.Response(
        '{"token":"test-token","user":{"id":1,"name":"Asha Mushi","email":"asha@example.com"}}',
        200,
      );
    }
    if (request.url.path.endsWith('/auth/phone/otp/verify')) {
      return http.Response(
        '{"token":"verified-phone-token","phone_number":"+255712345678"}',
        200,
      );
    }
    if (request.url.path.endsWith('/auth/phone/otp/request')) {
      return http.Response('{"message":"Code sent."}', 202);
    }
    if (request.url.path.endsWith('/conversations')) {
      if (includeRemoteConversation) {
        return http.Response(
          '{"data":[{"id":42,"name":"International friend","route":"airtext","unread_count":0,"messages":[{"id":91,"body":"Hello from overseas","sent_at":"2026-10-13T10:00:00Z","is_mine":false,"status":"sent"}]}]}',
          200,
        );
      }
      return http.Response(
        '{"data":[{"id":7,"name":"Mariam Hassan","email":"mariam@example.com","phone_number":"+255 718 220 901","route":"airtext","unread_count":0,"messages":[{"id":3,"body":"Habari! Umefika salama?","sent_at":"2026-10-13T10:38:00Z","sender_id":2,"is_mine":false,"status":"sent"},{"id":4,"body":"Ndio, nimefika. Asante!","sent_at":"2026-10-13T10:42:00Z","sender_id":1,"is_mine":true,"status":"read"}]},{"id":8,"name":"Juma K.","phone_number":"+255 712 884 102","route":"sms","unread_count":0,"messages":[{"id":5,"body":"The studio address is on its way.","sent_at":"2026-10-12T10:00:00Z","sender_id":2,"is_mine":false,"status":"sent"}]}]}',
        200,
      );
    }
    if (request.url.path.endsWith('/conversations/7/messages')) {
      return http.Response(
        '{"data":{"id":99,"body":"I am on my way","sent_at":"2026-10-13T10:45:00Z","sender_id":1,"is_mine":true,"status":"sent"}}',
        201,
      );
    }
    if (request.url.path.endsWith('/messages/91/translate')) {
      return http.Response(
        '{"translation":"Bonjour from abroad","target_language":"fr"}',
        200,
      );
    }
    if (request.url.path.endsWith('/read')) {
      return http.Response('{"message":"Messages marked as read."}', 200);
    }
    return http.Response('{"message":"Not found."}', 404);
  }),
);

AirTextApi _statusTestApi() => AirTextApi(
  baseUrl: 'https://airtext.test/api',
  tokenStore: _MemoryApiTokenStore('status-test-token'),
  client: MockClient((request) async {
    if (request.url.path.endsWith('/me')) {
      return http.Response(
        '{"id":1,"name":"Asha Mushi","email":"asha@example.com"}',
        200,
      );
    }
    if (request.url.path.endsWith('/conversations')) {
      return http.Response('{"data":[]}', 200);
    }
    if (request.url.path.endsWith('/statuses') && request.method == 'GET') {
      return http.Response('{"data":[]}', 200);
    }
    if (request.url.path.endsWith('/statuses') && request.method == 'POST') {
      return http.Response(
        '{"data":{"id":8,"author_name":"Asha Mushi","author_initials":"AM","body":"Habari za leo","background":"#00a884","created_at":"2026-10-09T10:00:00Z","is_mine":true,"has_viewed":false,"views_count":0,"screenshot_protected":true}}',
        201,
      );
    }
    if (request.url.path.endsWith('/statuses/8/viewers')) {
      return http.Response('{"data":[{"id":2,"name":"Mariam Hassan"}]}', 200);
    }
    if (request.url.path.endsWith('/statuses/8/likes')) {
      return http.Response('{"data":[{"id":3,"name":"Juma K."}]}', 200);
    }
    return http.Response('{"message":"Not found."}', 404);
  }),
);

Future<void> _pumpAirTextApp(WidgetTester tester, AirTextApi api) async {
  await tester.pumpWidget(AirTextApp(api: api));
  await tester.pumpAndSettle();
}

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'airtext.onboarding-complete': true,
      'airtext.language': 'English',
    }),
  );

  testWidgets('opens welcome and language selection on first launch', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('airtext.onboarding-complete', false);
    await preferences.remove('airtext.language');

    final api = _testApi(authenticated: false);
    await tester.pumpWidget(AirTextApp(api: api));
    await tester.pumpAndSettle();

    expect(find.text('Karibu AirText'), findsOneWidget);
    expect(find.text('Lugha unayopendelea'), findsOneWidget);
    await tester.ensureVisible(find.text('Kiswahili (Tanzania)'));
    await tester.tap(find.text('Kiswahili (Tanzania)'));
    await tester.pumpAndSettle();
    expect(find.text('Chagua lugha'), findsOneWidget);
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    expect(find.text('Welcome to AirText'), findsOneWidget);

    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Mandarin Chinese'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale?.languageCode, 'zh');
    expect(find.text('欢迎使用 AirText'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('sends the selected locale in the API Accept-Language header', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('airtext.language', 'French (Français)');
    String? acceptLanguage;
    final api = AirTextApi(
      baseUrl: 'https://airtext.test/api',
      tokenStore: _MemoryApiTokenStore(),
      client: MockClient((request) async {
        acceptLanguage = request.headers['Accept-Language'];
        return http.Response('{"id":1}', 200);
      }),
    );

    await api.getCurrentUser();

    expect(acceptLanguage, 'fr');
  });

  testWidgets('welcome screen fits and scrolls on a narrow phone viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('airtext.onboarding-complete', false);

    await tester.pumpWidget(AirTextApp(api: _testApi(authenticated: false)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign in or create account'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in or create account'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('shows destinations and opens Shop from the dock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(AirTextApp(api: _testApi()));
    await tester.pumpAndSettle();

    for (final label in ['Chats', 'Updates', 'Shop', 'Settings', 'Profile']) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.text('Shop').first);
    await tester.pumpAndSettle();
    expect(find.text('Air app Shop'), findsOneWidget);
    expect(find.text('Tourism SMS Bot'), findsOneWidget);
    expect(find.text('Gateway Recovery Suite'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Lead Capture Templates'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Search products and services'),
      'no matching product',
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No verified products are currently published.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Search products and services'),
      '',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(cupertino.CupertinoIcons.circle_grid_3x3));
    await tester.pumpAndSettle();
    expect(find.text('Updates'), findsWidgets);

    await tester.tap(find.byIcon(cupertino.CupertinoIcons.chat_bubble_2));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('changing app language in Settings updates visible UI', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(AirTextApp(api: _testApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(cupertino.CupertinoIcons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('ACCOUNT'), findsOneWidget);

    await tester.tap(find.text('App language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap to change app language'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('French (Français)'));
    await tester.pumpAndSettle();

    expect(find.text('Langue de l’application'), findsOneWidget);
    expect(find.text('Touchez pour changer la langue'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsWidgets);
    expect(find.text('CONFIDENTIALITÉ ET ACCÈS'), findsOneWidget);
    expect(find.text('French (Français)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('translates a synced message from its long-press menu', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('airtext.language', 'French (Français)');
    final api = _testApi(includeRemoteConversation: true);
    await tester.pumpWidget(AirTextApp(api: api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('International friend'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Hello from overseas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Translate message'));
    await tester.pumpAndSettle();

    expect(find.text('Hello from overseas'), findsOneWidget);
    expect(find.text('Bonjour from abroad'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Account opens access choices instead of welcome when signed out',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(AirTextApp(api: _testApi(authenticated: false)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in or create account'));
      await tester.pumpAndSettle();

      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Welcome to AirText'), findsNothing);

      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to AirText'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets('confirmed sign-out returns to welcome and hides app tabs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(AirTextApp(api: _statusTestApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(cupertino.CupertinoIcons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to AirText'), findsOneWidget);
    expect(find.text('Sign in or create account'), findsOneWidget);
    expect(find.text('Chats'), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('airtext.account'), isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('floating dock tolerates the initial zero-width frame', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = Size.zero;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(AirTextApp(api: _testApi()));
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('calls page keeps video calls within AirText chats', (
    WidgetTester tester,
  ) async {
    await _pumpAirTextApp(tester, _testApi());
    await tester.tap(find.byTooltip('Open command sphere'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Calls'));
    await tester.pumpAndSettle();

    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Start an AirText video call'), findsOneWidget);
    expect(find.text('Start a call from an AirText chat'), findsOneWidget);
    expect(find.text('Meeting link or room code'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('video call setup passes microphone and camera choices to join', (
    WidgetTester tester,
  ) async {
    bool? observedMicrophoneMuted;
    bool? observedCameraDisabled;

    await tester.pumpWidget(
      MaterialApp(
        home: VideoCallScreen(
          callerName: 'Neema Studio',
          onJoinCall:
              (
                callScreenContext, {
                required bool microphoneMuted,
                required bool cameraDisabled,
              }) async {
                observedMicrophoneMuted = microphoneMuted;
                observedCameraDisabled = cameraDisabled;
              },
        ),
      ),
    );

    expect(find.text('Neema Studio'), findsOneWidget);
    expect(find.text('Ready to join'), findsOneWidget);
    await tester.tap(find.byTooltip('Mute microphone'));
    await tester.tap(find.byTooltip('Turn camera off'));
    await tester.tap(find.text('Join call'));
    await tester.pumpAndSettle();

    expect(observedMicrophoneMuted, isTrue);
    expect(observedCameraDisabled, isTrue);
  });

  testWidgets('opens the in-app voice call screen from a contact action', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    await _pumpAirTextApp(tester, _testApi());

    await tester.tap(find.text('Mariam Hassan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(cupertino.CupertinoIcons.phone).first);
    await tester.pumpAndSettle();

    expect(find.text('AIR APP CALL'), findsOneWidget);
    expect(find.text('Voice calling unavailable'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('saves a new contact into the local directory', (
    WidgetTester tester,
  ) async {
    await _pumpAirTextApp(tester, _testApi());

    await tester.tap(find.byTooltip('Open command sphere'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Contacts'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add contact').first);
    await tester.pumpAndSettle();

    final fields = find.byType(cupertino.CupertinoTextField);
    await tester.enterText(fields.at(0), 'Asha Mushi');
    await tester.enterText(fields.at(1), '+255 755 123 456');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Asha Mushi'), findsOneWidget);
    expect(find.text('+255 755 123 456'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opens communities and shows insights for a new own status', (
    WidgetTester tester,
  ) async {
    await _pumpAirTextApp(tester, _statusTestApi());
    await tester.tap(find.byIcon(cupertino.CupertinoIcons.circle_grid_3x3));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Communities'));
    await tester.pumpAndSettle();
    expect(find.text('Air app Community'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write a text status'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField),
      'Habari za leo',
    );
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Status'));
    await tester.pumpAndSettle();
    expect(find.text('Status insights'), findsOneWidget);
    expect(find.text('0 views'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Mariam Hassan'), findsOneWidget);
    expect(find.text('Liked by'), findsOneWidget);
    expect(find.text('Juma K.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('registration requires email and phone OTP verification', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    final api = _testApi(authenticated: false);
    await tester.pumpWidget(AirTextApp(api: api));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in or create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agree and continue'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).first,
      'asha@example.com',
    );
    await tester.ensureVisible(find.text('Next / Send OTP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next / Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).last,
      '123456',
    );
    await tester.ensureVisible(find.text('Verify'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).first,
      'Asha Mushi',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Verify your phone'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).first,
      '712345678',
    );
    await tester.ensureVisible(find.text('Send SMS code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send SMS code'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).last,
      '123456',
    );
    await tester.ensureVisible(find.text('Verify & secure'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify & secure'));
    await tester.pumpAndSettle();
    expect(api.accessToken, 'verified-phone-token');
    expect(find.text('Chats'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('requires SMS verification for accounts with 2-step enabled', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    final api = _testApi(requirePhoneVerification: true, authenticated: false);
    await tester.pumpWidget(AirTextApp(api: api));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign in or create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in or create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).first,
      'asha@example.com',
    );
    await tester.ensureVisible(find.text('Next / Send OTP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next / Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).last,
      '123456',
    );
    await tester.ensureVisible(find.text('Verify'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your phone'), findsOneWidget);
    expect(find.textContaining('****5678'), findsOneWidget);
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).last,
      '654321',
    );
    await tester.ensureVisible(find.text('Verify and sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify and sign in'));
    await tester.pumpAndSettle();

    expect(api.isAuthenticated, isTrue);
    expect(find.text('Verify your phone'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  test('migrates an existing bearer token into secure storage', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('airtext.api-token', 'legacy-token');
    final tokenStore = _MemoryApiTokenStore();
    final api = AirTextApi(
      tokenStore: tokenStore,
      baseUrl: 'https://airtext.test/api',
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    await api.restoreToken();

    expect(api.isAuthenticated, isTrue);
    expect(tokenStore.token, 'legacy-token');
    expect(preferences.containsKey('airtext.api-token'), isFalse);
  });

  testWidgets('opens a conversation and sends a local message', (
    WidgetTester tester,
  ) async {
    await _pumpAirTextApp(tester, _testApi());

    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Mariam Hassan'), findsWidgets);

    await tester.tap(find.text('Mariam Hassan'));
    await tester.pumpAndSettle();
    expect(find.text('Habari! Umefika salama?'), findsOneWidget);

    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).last,
      'I am on my way',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send')));
    await tester.pump();

    expect(find.text('I am on my way'), findsOneWidget);
    await tester.longPress(find.text('I am on my way'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('React to message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('👍').last);
    await tester.pumpAndSettle();
    expect(find.text('👍'), findsOneWidget);
  });

  testWidgets('restores a backend session and sends a server message', (
    WidgetTester tester,
  ) async {
    final tokenStore = _MemoryApiTokenStore('saved-token');
    final requests = <http.Request>[];
    final api = AirTextApi(
      baseUrl: 'https://airtext.test/api',
      tokenStore: tokenStore,
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"id":2,"name":"Mariam Hassan","email":"mariam@example.com"}',
            200,
          );
        }
        if (request.url.path.endsWith('/conversations/7/messages')) {
          return http.Response(
            '{"data":{"id":4,"body":"Backend reply","sent_at":"2026-10-08T10:45:00Z","sender_id":2,"is_mine":true,"status":"sent"}}',
            201,
          );
        }
        if (request.url.path.endsWith('/conversations')) {
          return http.Response(
            '{"data":[{"id":7,"name":"Mariam Hassan","email":"mariam@example.com","route":"airtext","messages":[{"id":3,"body":"Server message","sent_at":"2026-10-08T10:42:00Z","sender_id":1,"is_mine":false,"status":"sent"}]}]}',
            200,
          );
        }
        return http.Response('{"message":"Not found."}', 404);
      }),
    );

    await tester.pumpWidget(AirTextApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Server message'), findsOneWidget);

    await tester.tap(find.text('Mariam Hassan'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).last,
      'Backend reply',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send')));
    await tester.pumpAndSettle();

    expect(find.text('Backend reply'), findsOneWidget);
    expect(
      requests.any(
        (request) =>
            request.method == 'POST' &&
            request.headers['authorization'] == 'Bearer saved-token',
      ),
      isTrue,
    );
  });

  testWidgets('keeps the saved account session when the server is offline', (
    WidgetTester tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'airtext.account',
      '{"id":2,"name":"Mariam Hassan","email":"mariam@example.com"}',
    );
    final tokenStore = _MemoryApiTokenStore('saved-token');
    final api = AirTextApi(
      baseUrl: 'https://airtext.test/api',
      tokenStore: tokenStore,
      client: MockClient(
        (_) async => http.Response('{"message":"Server unavailable."}', 503),
      ),
    );

    await tester.pumpWidget(AirTextApp(api: api));
    await tester.pumpAndSettle();

    expect(find.text('Sign in or create account'), findsNothing);
    expect(find.text('Chats'), findsWidgets);
    expect(tokenStore.token, 'saved-token');
    expect(find.text('Mariam Hassan'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('restores the saved account session after an app restart', (
    WidgetTester tester,
  ) async {
    final tokenStore = _MemoryApiTokenStore('saved-token');
    AirTextApi createApi() => AirTextApi(
      baseUrl: 'https://airtext.test/api',
      tokenStore: tokenStore,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          return http.Response(
            '{"id":2,"name":"Mariam Hassan","email":"mariam@example.com"}',
            200,
          );
        }
        if (request.url.path.endsWith('/conversations')) {
          return http.Response('{"data":[]}', 200);
        }
        if (request.url.path.endsWith('/statuses')) {
          return http.Response('{"data":[]}', 200);
        }
        return http.Response('{}', 200);
      }),
    );

    await tester.pumpWidget(AirTextApp(api: createApi()));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(AirTextApp(api: createApi()));
    await tester.pumpAndSettle();

    expect(find.text('Sign in or create account'), findsNothing);
    expect(find.text('Chats'), findsWidgets);
    await tester.tap(find.text('Profile').first);
    await tester.pumpAndSettle();
    expect(find.text('Mariam Hassan'), findsWidgets);
    expect(tokenStore.token, 'saved-token');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('requires explicit confirmation before deleting an account', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    final tokenStore = _MemoryApiTokenStore('saved-token');
    var deletionRequested = false;
    final api = AirTextApi(
      baseUrl: 'https://airtext.test/api',
      tokenStore: tokenStore,
      client: MockClient((request) async {
        if (request.url.path.endsWith('/me') && request.method == 'GET') {
          return http.Response(
            '{"id":2,"name":"Mariam Hassan","email":"mariam@example.com"}',
            200,
          );
        }
        if (request.url.path.endsWith('/conversations')) {
          return http.Response('{"data":[]}', 200);
        }
        if (request.url.path.endsWith('/me') && request.method == 'DELETE') {
          deletionRequested = true;
          return http.Response('{"message":"Account deleted."}', 200);
        }
        return http.Response('{"message":"Not found."}', 404);
      }),
    );

    await tester.pumpWidget(AirTextApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(cupertino.CupertinoIcons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account').first);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('This action cannot be undone.'),
      findsOneWidget,
    );
    expect(find.textContaining('conversations and messages'), findsOneWidget);
    expect(deletionRequested, isFalse);
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).last,
      'DELETE',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account').last);
    await tester.pumpAndSettle();

    expect(deletionRequested, isTrue);
    expect(tokenStore.token, isNull);
    expect(find.text('Sign in or create account'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('shows the native attachment actions and honest upload state', (
    WidgetTester tester,
  ) async {
    await _pumpAirTextApp(tester, _testApi());
    await tester.tap(find.text('Mariam Hassan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add attachment'));
    await tester.pumpAndSettle();
    for (final action in [
      'Take Photo or Video',
      'Photo & Video Library',
      'Document',
      'Location',
      'Contact',
    ]) {
      expect(find.text(action), findsOneWidget);
    }

    await tester.tap(find.text('Document'));
    await tester.pumpAndSettle();
    expect(find.text('Document sharing'), findsOneWidget);
    expect(
      find.text(
        'The Air app message API currently accepts text messages only.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('appearance page switches app theme and opens chat theme', (
    WidgetTester tester,
  ) async {
    await _pumpAirTextApp(tester, _testApi());
    await tester.tap(find.byIcon(cupertino.CupertinoIcons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    expect(find.text('APP THEME'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('APP THEME'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Chat Theme'));
    await tester.pumpAndSettle();
    expect(find.text('ACCENT COLOR'), findsOneWidget);
    await tester.tap(find.text('Ocean Blue'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opens call history from the Chats header', (
    WidgetTester tester,
  ) async {
    await _pumpAirTextApp(tester, _testApi());
    await tester.tap(find.byTooltip('Open command sphere'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Calls'));
    await tester.pumpAndSettle();

    expect(find.text('Calls'), findsWidgets);
    expect(find.text('RECENT CALLS'), findsOneWidget);
    expect(find.text('No recent calls'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opens group creation from the chat overflow menu', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    await _pumpAirTextApp(tester, _testApi());
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Link a device'), findsOneWidget);
    expect(find.text('Broadcast list'), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);
    await tester.tap(find.text('New group'));
    await tester.pumpAndSettle();

    expect(find.text('New group'), findsOneWidget);
    expect(find.text('Group name'), findsOneWidget);
    expect(find.text('Create group (0)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('opens contact privacy and disappearing-message settings', (
    WidgetTester tester,
  ) async {
    await _pumpAirTextApp(tester, _testApi());

    await tester.tap(find.text('Mariam Hassan').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(cupertino.CupertinoIcons.info));
    await tester.pumpAndSettle();

    expect(find.text('Disappearing Messages'), findsOneWidget);
    expect(find.text('Clear Chat'), findsOneWidget);
    expect(find.text('Block Contact'), findsOneWidget);
    expect(find.text('Report Contact'), findsOneWidget);

    await tester.tap(find.text('Disappearing Messages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(find.text('7 days'), findsOneWidget);

    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(find.text('Share Last Seen'), findsOneWidget);
    expect(find.text('Read Receipts'), findsOneWidget);

    await tester.tap(find.byType(cupertino.CupertinoSwitch).first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<cupertino.CupertinoSwitch>(
            find.byType(cupertino.CupertinoSwitch).first,
          )
          .value,
      isFalse,
    );
  });
}
