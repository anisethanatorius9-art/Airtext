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

AirTextApi _testApi() => AirTextApi(
  baseUrl: 'https://airtext.test/api',
  tokenStore: _MemoryApiTokenStore(),
  client: MockClient((request) async {
    if (request.url.path.endsWith('/auth/otp/request')) {
      return http.Response('{"message":"Code sent."}', 202);
    }
    if (request.url.path.endsWith('/auth/otp/verify')) {
      return http.Response(
        '{"token":"test-token","user":{"id":1,"name":"Asha Mushi","email":"asha@example.com"}}',
        200,
      );
    }
    if (request.url.path.endsWith('/conversations')) {
      return http.Response('{"data":[]}', 200);
    }
    return http.Response('{"message":"Not found."}', 404);
  }),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the four destinations in the floating navigation dock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(AirTextApp(api: _testApi()));

    for (final label in ['Nexus', 'Mesh', 'Vault', 'Profile']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.byIcon(cupertino.CupertinoIcons.circle_grid_3x3));
    await tester.pumpAndSettle();
    expect(find.text('Status'), findsWidgets);

    await tester.tap(find.byIcon(cupertino.CupertinoIcons.chat_bubble_2));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
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

  testWidgets('calls page offers phone and video group call actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(AirTextApp(api: _testApi()));
    await tester.tap(find.byTooltip('Open command sphere'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Calls'));
    await tester.pumpAndSettle();

    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Start a video or group call'), findsOneWidget);
    expect(find.text('Meeting link or room code'), findsOneWidget);

    await tester.tap(find.text('Start a video or group call'));
    await tester.pumpAndSettle();
    expect(find.text('Share this code or link so others can join:'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saves a new contact into the local directory', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(AirTextApp(api: _testApi()));

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
    await tester.pumpWidget(AirTextApp(api: _testApi()));
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
    expect(find.text('0 likes'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('saves profile identity and signs in with an email OTP', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(AirTextApp(api: _testApi()));
    await tester.tap(find.byIcon(cupertino.CupertinoIcons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo, username and about'));
    await tester.pumpAndSettle();

    final fields = find.byType(cupertino.CupertinoTextField);
    await tester.enterText(fields.at(0), 'Asha Mushi');
    await tester.enterText(fields.at(1), 'ashamushi');
    await tester.enterText(fields.at(2), 'Designer in Dar');
    await tester.ensureVisible(find.text('Save profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile saved on this device.'), findsOneWidget);

    await tester.ensureVisible(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).first,
      'asha@example.com',
    );
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.text('6-digit email code'), findsOneWidget);
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField).last,
      '123456',
    );
    await tester.tap(find.text('Verify and sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Nexus'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
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
    await tester.pumpWidget(AirTextApp(api: _testApi()));

    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Mariam Hassan'), findsOneWidget);

    await tester.tap(find.text('Mariam Hassan'));
    await tester.pumpAndSettle();
    expect(find.text('Habari! Umefika salama?'), findsOneWidget);

    await tester.tap(find.byTooltip('Add emoji'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('emoji-picker')), findsOneWidget);
    await tester.tap(find.byTooltip('Add emoji'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('emoji-picker')), findsNothing);

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

  testWidgets('shows the native attachment actions and honest upload state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(AirTextApp(api: _testApi()));
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
    await tester.pumpWidget(AirTextApp(api: _testApi()));
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
    await tester.pumpWidget(AirTextApp(api: _testApi()));
    await tester.tap(find.byTooltip('Open command sphere'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Calls'));
    await tester.pumpAndSettle();

    expect(find.text('Calls'), findsOneWidget);
    expect(find.text('RECENT CALLS'), findsOneWidget);
    expect(find.text('Mariam Hassan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('creates a group from the chat overflow menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(AirTextApp(api: _testApi()));
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Link a device'), findsOneWidget);
    expect(find.text('Broadcast list'), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);
    await tester.tap(find.text('New group'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.enterText(
      find.byType(cupertino.CupertinoTextField),
      'Dar Creatives',
    );
    await tester.tap(find.text('Create group (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Dar Creatives'), findsOneWidget);
    expect(find.text('Group · 1 members'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opens contact privacy and disappearing-message settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(AirTextApp(api: _testApi()));

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
