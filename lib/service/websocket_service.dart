import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'websocket_client.dart';

class WebSocketService extends GetxService {
  final Map<String, WebSocketClient> _clients = {};

  Future<WebSocketClient> connect({
    required String name,
    String? url,
    MessageListener? listener,
    bool force = false,
  }) async {
    if (_clients.containsKey(name) &&
        _clients[name]!.status.value == WsStatus.connected) {
      return _clients[name]!._addListener(listener);
    }

    url ??= 'ws://${ApiClient().address}/ws/$name';
    final client = WebSocketClient(name: name, url: url)._addListener(listener);
    _clients[name] = client;
    await client._connect();
    return client;
  }

  Future<void> send(String name, String message) async {
    final client = _clients[name];
    if (client != null) {
      client.send(message);
    } else {
      printInfo(info: 'ws[$name] want to send, but not connected');
    }
  }

  Future<void> close(
    String name, {
    int code = WebSocketStatus.normalClosure,
    String reason = 'normal close',
    bool reconnect = false,
  }) async {
    final client = _clients[name];
    if (client != null) {
      await client._close(code, reason, reconnect: reconnect);
      _clients.remove(name);
    }
    printInfo(info: 'ws[$name] closed');
  }

  Future<void> closeAll() async {
    for (final client in _clients.values) {
      await client._close(WebSocketStatus.normalClosure, 'global close');
    }
    _clients.clear();
    printInfo(info: 'ws all closed');
  }

  void removeAllListeners(String name) {
    final client = _clients[name];
    if (client != null) {
      client._listeners.clear();
    }
    printInfo(info: 'ws[$name] listeners removed');
  }
}
