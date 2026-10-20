import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class AirTextCallSignal {
  const AirTextCallSignal({
    required this.callId,
    required this.kind,
    required this.senderId,
    required this.payload,
  });

  final String callId;
  final String kind;
  final int senderId;
  final Map<String, dynamic> payload;

  factory AirTextCallSignal.fromJson(Map<String, dynamic> json) {
    return AirTextCallSignal(
      callId: json['call_id'] as String,
      kind: json['kind'] as String,
      senderId: json['sender_id'] as int,
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
    );
  }
}

class AirTextCallClient {
  AirTextCallClient({
    required this.apiBaseUri,
    required this.token,
    required this.reverbHost,
    required this.reverbKey,
    this.reverbPort = 8080,
    this.useTls = false,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final Uri apiBaseUri;
  final String token;
  final String reverbHost;
  final String reverbKey;
  final int reverbPort;
  final bool useTls;
  final http.Client _httpClient;
  final StreamController<AirTextCallSignal> _signals =
      StreamController<AirTextCallSignal>.broadcast();
  final StreamController<int> _messageUpdates = StreamController<int>.broadcast();

  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Completer<void>? _subscribed;
  String? _socketId;
  int? _userId;

  Stream<AirTextCallSignal> get signals => _signals.stream;
  Stream<int> get messageUpdates => _messageUpdates.stream;

  Future<void> connect(int userId) async {
    if (reverbHost.isEmpty || reverbKey.isEmpty) {
      throw const AirTextCallClientException(
        'AirText calling is not configured on this build.',
      );
    }

    _userId = userId;
    final scheme = useTls ? 'wss' : 'ws';
    final uri = Uri(
      scheme: scheme,
      host: reverbHost,
      port: reverbPort,
      path: '/app/$reverbKey',
      queryParameters: const {
        'protocol': '7',
        'client': 'js',
        'version': '8.4.0',
        'flash': 'false',
      },
    );

    _subscribed = Completer<void>();
    _socket = WebSocketChannel.connect(uri);
    await _socket!.ready.timeout(const Duration(seconds: 10));
    _socketSubscription = _socket!.stream.listen(
      _handleSocketMessage,
      onError: _signals.addError,
      onDone: () {
        if (!(_subscribed?.isCompleted ?? true)) {
          _subscribed!.completeError(
            const AirTextCallClientException('AirText call connection closed.'),
          );
        }
      },
    );
    await _subscribed!.future.timeout(const Duration(seconds: 10));
  }

  Future<Map<String, dynamic>> createCall(int conversationId) =>
      _request('POST', '/calls', body: {'conversation_id': conversationId});

  Future<Map<String, dynamic>> getActiveCall() =>
      _request('GET', '/calls/active');

  Future<Map<String, dynamic>> getCall(String callId) =>
      _request('GET', '/calls/$callId');

  Future<List<Map<String, dynamic>>> getIceServers() async {
    final response = await _request('GET', '/calls/ice-servers');
    return (response['data'] as List<dynamic>)
        .map((server) => Map<String, dynamic>.from(server as Map))
        .toList();
  }

  Future<void> acceptCall(String callId) async {
    await _request('POST', '/calls/$callId/accept');
  }

  Future<void> declineCall(String callId) async {
    await _request('POST', '/calls/$callId/decline');
  }

  Future<void> sendSignal(
    String callId,
    String kind,
    Map<String, dynamic> payload,
  ) async {
    await _request(
      'POST',
      '/calls/$callId/signals',
      body: {'kind': kind, 'payload': payload},
    );
  }

  Future<void> endCall(String callId) async {
    await _request('POST', '/calls/$callId/end');
  }

  Future<void> _handleSocketMessage(dynamic message) async {
    final frame = _decodeMap(message);
    final event = frame['event'] as String?;
    final data = _decodeMap(frame['data']);

    if (event == 'pusher:connection_established') {
      _socketId = data['socket_id'] as String?;
      if (_socketId == null) {
        _subscribed?.completeError(
          const AirTextCallClientException(
            'Reverb did not provide a socket ID.',
          ),
        );
        return;
      }
      await _subscribePrivateUserChannel();
      return;
    }

    if (event == 'pusher_internal:subscription_succeeded' ||
        event == 'pusher:subscription_succeeded') {
      if (!(_subscribed?.isCompleted ?? true)) _subscribed!.complete();
      return;
    }

    if (event == 'pusher:subscription_error') {
      if (!(_subscribed?.isCompleted ?? true)) {
        _subscribed!.completeError(
          const AirTextCallClientException(
            'Reverb rejected the AirText call channel subscription.',
          ),
        );
      }
      return;
    }

    if (event == 'pusher:ping') {
      _socket?.sink.add(jsonEncode({'event': 'pusher:pong', 'data': {}}));
      return;
    }

    if (event == 'call.signal') {
      _signals.add(AirTextCallSignal.fromJson(data));
      return;
    }

    if (event == 'message.sent') {
      final conversationId = data['conversation_id'];
      if (conversationId is int) _messageUpdates.add(conversationId);
    }
  }

  Future<void> _subscribePrivateUserChannel() async {
    final channelName = 'private-users.$_userId';
    final authUri = apiBaseUri.replace(
      path: '${apiBaseUri.path}/broadcasting/auth',
    );
    final response = await _httpClient.post(
      authUri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {'socket_id': _socketId!, 'channel_name': channelName},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AirTextCallClientException(
        'Could not authenticate the AirText call channel (${response.statusCode}).',
      );
    }

    final authorization = jsonDecode(response.body) as Map<String, dynamic>;
    _socket?.sink.add(
      jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': channelName, 'auth': authorization['auth']},
      }),
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final uri = apiBaseUri.replace(path: '${apiBaseUri.path}$path');
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        ...?body == null ? null : {'Content-Type': 'application/json'},
      });
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AirTextCallClientException(
          decoded['message'] as String? ??
              'AirText call request failed (${response.statusCode}).',
        );
      }
      return decoded;
    } on http.ClientException {
      throw const AirTextCallClientException(
        'Could not reach the AirText call server.',
      );
    }
  }

  Map<String, dynamic> _decodeMap(dynamic value) {
    final decoded = value is String ? jsonDecode(value) : value;
    return Map<String, dynamic>.from(decoded as Map? ?? {});
  }

  Future<void> dispose() async {
    await _socketSubscription?.cancel();
    await _socket?.sink.close();
    await _signals.close();
    await _messageUpdates.close();
    _httpClient.close();
  }
}

class AirTextCallClientException implements Exception {
  const AirTextCallClientException(this.message);

  final String message;

  @override
  String toString() => message;
}
