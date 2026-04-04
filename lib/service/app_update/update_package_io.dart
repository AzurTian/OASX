import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Holds the active download resources so the caller can cancel them.
class UpdateDownloadSession {
  HttpClient? _httpClient;
  bool _isCancelled = false;

  /// Attaches the currently active HTTP client.
  void attach(HttpClient httpClient) {
    _httpClient = httpClient;
  }

  /// Cancels the active download session.
  void cancel() {
    _isCancelled = true;
    _httpClient?.close(force: true);
  }

  /// Returns true when the download was cancelled by the user.
  bool get isCancelled => _isCancelled;
}

/// Signals that the update download was cancelled by the user.
class UpdateDownloadCancelledException implements Exception {
  const UpdateDownloadCancelledException();
}

/// Handles download and checksum work for app update packages.
class UpdatePackageIo {
  /// Fetches a JSON object from [url] with optional proxy support.
  static Future<Map<String, dynamic>> fetchJsonMap(
    String url, {
    String? proxyUrl,
  }) async {
    final httpClient = HttpClient();
    _configureProxy(httpClient, proxyUrl);
    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('request_failed_${response.statusCode}');
      }
      final body = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('invalid_json_payload');
      }
      return decoded;
    } finally {
      httpClient.close();
    }
  }

  /// Downloads a remote asset to [filePath] and emits byte progress updates.
  static Future<void> downloadToFile(
    String url,
    String filePath, {
    String? proxyUrl,
    UpdateDownloadSession? session,
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    final httpClient = HttpClient();
    session?.attach(httpClient);
    _configureProxy(httpClient, proxyUrl);
    IOSink? output;
    var receivedBytes = 0;
    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('download_failed_${response.statusCode}');
      }
      final totalBytes = response.contentLength;
      output = File(filePath).openWrite();
      await for (final chunk in response) {
        if (session?.isCancelled ?? false) {
          throw const UpdateDownloadCancelledException();
        }
        receivedBytes += chunk.length;
        output.add(chunk);
        onProgress?.call(receivedBytes, totalBytes);
      }
    } catch (error) {
      if (session?.isCancelled ?? false) {
        throw const UpdateDownloadCancelledException();
      }
      rethrow;
    } finally {
      await output?.close();
      if (session?.isCancelled ?? false) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      httpClient.close();
    }
  }

  /// Computes a SHA-256 digest for the file at [filePath].
  static Future<String> computeSha256(String filePath) async {
    final fileBytes = await File(filePath).readAsBytes();
    final digest = sha256.convert(fileBytes);
    return digest.toString();
  }

  /// Normalizes GitHub digest strings such as `sha256:<hash>`.
  static String? normalizeDigest(String? digest) {
    if (digest == null || digest.trim().isEmpty) {
      return null;
    }
    return digest.split(':').last.trim().toLowerCase();
  }

  /// Applies an optional proxy URL to the given [httpClient].
  static void _configureProxy(HttpClient httpClient, String? proxyUrl) {
    final raw = proxyUrl?.trim() ?? '';
    if (raw.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) {
      return;
    }
    final port = uri.port > 0 ? uri.port : 80;
    httpClient.findProxy = (_) => 'PROXY ${uri.host}:$port; DIRECT';
  }
}
