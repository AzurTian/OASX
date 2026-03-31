import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Connection states reported by the generic SSE client.
enum ApiSseConnectionState {
  connecting,
  connected,
  reconnecting,
  error,
}

/// One parsed SSE event.
class ApiSseEvent {
  /// Creates an SSE event model.
  ApiSseEvent({
    required this.id,
    required this.name,
    required this.data,
  });

  /// Event id.
  final String id;

  /// Event name.
  final String name;

  /// Event payload.
  final String data;
}

/// Generic SSE client with reconnect support.
class ApiSseClient {
  /// Creates one SSE client instance.
  ApiSseClient({
    required this.url,
    required this.onEvent,
    required this.onStateChanged,
    this.retryDelay = const Duration(seconds: 3),
  });

  /// SSE endpoint URL.
  final Uri url;

  /// Callback invoked for every parsed event.
  final void Function(ApiSseEvent event) onEvent;

  /// Callback invoked when connection state changes.
  final void Function(ApiSseConnectionState state, String? message)
      onStateChanged;

  /// Delay used before reconnecting after a failure.
  final Duration retryDelay;

  StreamSubscription<String>? _lineSubscription;
  HttpClient? _client;
  int _generation = 0;
  bool _disposed = false;

  /// Starts the SSE stream and reconnect loop.
  Future<void> connect() async {
    _disposed = false;
    _generation++;
    await _open(_generation, initial: true);
  }

  /// Stops the SSE stream and prevents future reconnects.
  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    await _closeTransport();
  }

  Future<void> _open(int generation, {required bool initial}) async {
    if (!_isActive(generation)) {
      return;
    }
    await _closeTransport();
    onStateChanged(
      initial
          ? ApiSseConnectionState.connecting
          : ApiSseConnectionState.reconnecting,
      null,
    );
    final client = HttpClient();
    _client = client;
    try {
      final request = await client.getUrl(url);
      request.persistentConnection = true;
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      request.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
      final response = await request.close();
      if (!_isActive(generation)) {
        client.close();
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _handleFailure(
          generation,
          'HTTP ${response.statusCode} ${response.reasonPhrase}'.trim(),
        );
        return;
      }
      final mimeType = response.headers.contentType?.mimeType ?? '';
      if (mimeType != 'text/event-stream') {
        await _handleSnapshotFallback(response, generation);
        return;
      }
      onStateChanged(ApiSseConnectionState.connected, null);
      _listenResponse(response, generation);
    } catch (error) {
      _handleFailure(generation, error.toString());
    }
  }

  Future<void> _handleSnapshotFallback(
    HttpClientResponse response,
    int generation,
  ) async {
    if (!_isActive(generation)) {
      return;
    }
    final body = await response.transform(utf8.decoder).join();
    if (!_isActive(generation)) {
      return;
    }
    final payload = body.trim();
    if (payload.isNotEmpty) {
      onEvent(ApiSseEvent(id: '', name: 'snapshot', data: payload));
    }
    onStateChanged(ApiSseConnectionState.connected, null);
  }

  void _listenResponse(HttpClientResponse response, int generation) {
    var currentId = '';
    var currentEvent = '';
    var dataBuffer = StringBuffer();
    _lineSubscription = response
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (!_isActive(generation)) {
          return;
        }
        if (line.isEmpty) {
          _emitEvent(currentId, currentEvent, dataBuffer);
          currentId = '';
          currentEvent = '';
          dataBuffer = StringBuffer();
          return;
        }
        if (line.startsWith(':')) {
          return;
        }
        _consumeLine(
          line,
          onId: (value) => currentId = value,
          onEvent: (value) => currentEvent = value,
          onData: (value) => dataBuffer.writeln(value),
        );
      },
      onDone: () => _handleFailure(generation, 'stream_closed'),
      onError: (Object error, StackTrace stackTrace) {
        _handleFailure(generation, error.toString());
      },
      cancelOnError: true,
    );
  }

  void _consumeLine(
    String line, {
    required void Function(String value) onId,
    required void Function(String value) onEvent,
    required void Function(String value) onData,
  }) {
    final separator = line.indexOf(':');
    final field = separator == -1 ? line : line.substring(0, separator);
    var value = separator == -1 ? '' : line.substring(separator + 1);
    if (value.startsWith(' ')) {
      value = value.substring(1);
    }
    switch (field) {
      case 'id':
        onId(value);
        return;
      case 'event':
        onEvent(value);
        return;
      case 'data':
        onData(value);
        return;
      default:
        return;
    }
  }

  void _emitEvent(String id, String event, StringBuffer dataBuffer) {
    if (id.isEmpty && event.isEmpty && dataBuffer.isEmpty) {
      return;
    }
    final payload = dataBuffer.toString().trimRight();
    onEvent(ApiSseEvent(id: id, name: event, data: payload));
  }

  void _handleFailure(int generation, String message) {
    if (!_isActive(generation)) {
      return;
    }
    final silentReconnect = message == 'stream_closed';
    onStateChanged(
      silentReconnect
          ? ApiSseConnectionState.reconnecting
          : ApiSseConnectionState.error,
      silentReconnect ? null : message,
    );
    Future.delayed(retryDelay, () {
      if (_isActive(generation)) {
        unawaited(_open(generation, initial: false));
      }
    });
  }

  Future<void> _closeTransport() async {
    await _lineSubscription?.cancel();
    _lineSubscription = null;
    _client?.close();
    _client = null;
  }

  bool _isActive(int generation) {
    return !_disposed && generation == _generation;
  }
}
