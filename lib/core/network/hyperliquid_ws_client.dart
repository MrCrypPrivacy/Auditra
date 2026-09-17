import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/dashboard/domain/fill.dart';

class HyperliquidWsClient {
  WebSocketChannel? _channel;
  StreamController<Fill>? _controller;

  Stream<Fill> subscribeUserFills(String address) {
    _channel?.sink.close();
    _controller = StreamController<Fill>.broadcast(onCancel: dispose);

    _channel = WebSocketChannel.connect(
      Uri.parse('wss://api.hyperliquid.xyz/ws'),
    );

    _channel!.sink.add(jsonEncode({
      'method': 'subscribe',
      'subscription': {'type': 'userFills', 'user': address},
    }));

    _channel!.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message as String) as Map<String, dynamic>;
          if (decoded['channel'] != 'userFills') return;

          final data = decoded['data'] as Map<String, dynamic>;
          final fillsJson = data['fills'] as List<dynamic>? ?? [];

          for (final raw in fillsJson) {
            _controller?.add(Fill.fromJson(raw as Map<String, dynamic>));
          }
        } catch (_) {
          // Ignore malformed or unrelated messages on the socket.
        }
      },
      onError: _controller?.addError,
      onDone: () => _controller?.close(),
    );

    return _controller!.stream;
  }

  void dispose() {
    _channel?.sink.close();
    _channel = null;
  }
}
