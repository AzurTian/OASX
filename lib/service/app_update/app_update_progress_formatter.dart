import 'package:get/get.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Formats human-readable download progress strings for the updater.
class AppUpdateProgressFormatter {
  /// Formats the current download progress text.
  static String formatProgress({
    required int receivedBytes,
    required int totalBytes,
  }) {
    final received = _formatBytes(receivedBytes);
    if (totalBytes <= 0) {
      return I18n.updateDownloadProgressUnknown.trParams({
        'received': received,
      });
    }
    final total = _formatBytes(totalBytes);
    final percent = ((receivedBytes / totalBytes) * 100).clamp(0, 100);
    return I18n.updateDownloadProgress.trParams({
      'received': received,
      'total': total,
      'percent': percent.toStringAsFixed(0),
    });
  }

  /// Formats a byte count into a compact readable size.
  static String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final decimals = unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }
}
