import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Contains shared app-version helpers for update checks.
class AppVersionUtils {
  /// Returns true when [latest] is newer than [current].
  static bool compareVersion(String current, String latest) {
    final currentParts = _normalizeVersion(current);
    final latestParts = _normalizeVersion(latest);
    final maxLength = currentParts.length > latestParts.length
        ? currentParts.length
        : latestParts.length;
    for (var index = 0; index < maxLength; index++) {
      final currentValue =
          index < currentParts.length ? currentParts[index] : 0;
      final latestValue = index < latestParts.length ? latestParts[index] : 0;
      if (latestValue > currentValue) {
        return true;
      }
      if (latestValue < currentValue) {
        return false;
      }
    }
    return false;
  }

  /// Returns the normalized application version string.
  static Future<String> getCurrentVersion() async {
    if (!kReleaseMode) {
      return 'v0.0.1';
    }
    return 'v0.2.5';
    final packageInfo = await PackageInfo.fromPlatform();
    return 'v${packageInfo.version}'.split('-')[0];
  }

  /// Normalizes a semantic version string into integer parts.
  static List<int> _normalizeVersion(String version) {
    final normalized = version.trim().replaceFirst(RegExp('^v'), '');
    return normalized
        .split(RegExp(r'[.\-]'))
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
