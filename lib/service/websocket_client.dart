part of 'websocket_service.dart';

typedef MessageListener = void Function(dynamic message);

enum WsStatus {
  connecting,
  connected,
  reconnecting,
  closed,
  error,
}

class WebSocketClient {
  WebSocketClient({
    required this.name,
    required this.url,
  });

  final String name;
  final String url;

  WebSocketChannel? _channel;
  final List<MessageListener> _listeners = [];
  bool _shouldReconnect = true;
  int _reconnectCount = 0;
  static const int maxReconnect = 3;
  static const int maxReconnectAfterClosed = 2;
  final status = WsStatus.connecting.obs;

  Future<void> send(String data) async {
    if (status.value == WsStatus.connected) {
      try {
        _channel?.sink.add(data);
      } catch (e) {
        printError(info: e.toString());
        status.value = WsStatus.error;
        await _reconnect();
      }
    } else {
      printInfo(info: "[$name] cannot send, status=${status.value}");
      await _reconnect();
    }
  }

  Future<T?> sendAndWaitOnce<T>(
    String data, {
    T Function(dynamic msg)? onResult,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return sendAndWaitUntil(
      data,
      check: (msg) async => true,
      onResult: onResult,
      timeout: timeout,
    );
  }

  Future<T?> sendAndWaitUntil<T>(
    String data, {
    required Future<bool> Function(dynamic msg) check,
    T Function(dynamic msg)? onResult,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<T?>();

    late MessageListener tmpListener;
    tmpListener = (msg) async {
      try {
        if (await check(msg) && !completer.isCompleted) {
          if (onResult != null) {
            completer.complete(onResult(msg));
          } else {
            completer.complete(msg);
          }
          _removeListener(tmpListener);
        }
      } catch (_) {}
    };

    _addListener(tmpListener);
    send(data);

    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(null);
        _removeListener(tmpListener);
      }
    });

    return completer.future;
  }

  Future<void> _connect() async {
    try {
      status.value = WsStatus.connecting;
      var address = url;
      if (address.contains('http://')) {
        address = address.replaceAll('http://', '');
      }
      printInfo(info: "ws[$name] connecting to $address");
      _channel = WebSocketChannel.connect(Uri.parse(address));
      await _channel!.ready;
      status.value = WsStatus.connected;
      printInfo(info: "ws[$name] connected!");

      _channel!.stream.listen(
        (msg) {
          for (final listener in List.from(_listeners)) {
            listener(msg);
          }
        },
        onDone: _reconnect,
        onError: (e) async {
          printError(info: "ws[$name] error: $e");
          status.value = WsStatus.error;
          await _reconnect();
        },
      );

      _channel!.sink.done.then((_) async {
        printInfo(info: "ws[$name] sink closed");
        if (status.value != WsStatus.closed) {
          status.value = WsStatus.closed;
          await _reconnect();
        }
      });
    } on SocketException catch (e) {
      printError(info: "ws[$name] SocketException: $e");
      status.value = WsStatus.error;
      await _reconnect();
    } on Exception catch (e) {
      printError(info: "ws[$name] Exception: $e");
      status.value = WsStatus.error;
      await _reconnect();
    }
  }

  WebSocketClient _addListener(MessageListener? listener) {
    if (listener != null && !_listeners.contains(listener)) {
      _listeners.add(listener);
      printInfo(info: "ws[$name] listener added");
    }
    return this;
  }

  void _removeListener(MessageListener listener) {
    _listeners.remove(listener);
    printInfo(info: "ws[$name] listener removed");
  }

  Future<void> _close(int code, String reason, {bool reconnect = false}) async {
    _shouldReconnect = reconnect;
    try {
      await _channel?.sink.close(code, reason);
    } catch (e) {
      printError(info: e.toString());
    }
    status.value = WsStatus.closed;
    _listeners.clear();
    printInfo(info: "ws[$name] closed: $reason");
  }

  Future<void> _reconnect() async {
    if (!_shouldReconnect) {
      printInfo(info: "ws[$name] not should reconnect");
      status.value = WsStatus.closed;
      return;
    }
    if (status.value == WsStatus.connected ||
        status.value == WsStatus.connecting ||
        status.value == WsStatus.reconnecting) {
      return;
    }
    _reconnectCount++;
    if (_reconnectCount > maxReconnect) {
      printError(
          info: "ws[$name] reconnect failed more than $maxReconnect times");
      if (status.value != WsStatus.closed) {
        printError(info: 'ws[$name] try close and reconnect');
        await _close(
          WebSocketStatus.normalClosure,
          'client try connect, but failed',
        ).timeout(const Duration(seconds: 2), onTimeout: () => false);
      }
      status.value = WsStatus.closed;
      if (_reconnectCount > maxReconnect + maxReconnectAfterClosed) {
        _reconnectCount = 0;
        printError(info: 'ws[$name] try reconnect after closed failed, finish');
        return;
      }
    }
    printInfo(info: "ws[$name] reconnecting... ($_reconnectCount)");
    status.value = WsStatus.reconnecting;
    Future.delayed(
      Duration(seconds: _reconnectCount <= 1 ? 0 : 2),
      () => _connect(),
    );
  }
}
