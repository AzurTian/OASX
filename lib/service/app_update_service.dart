import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/api/github_release_model.dart';
import 'package:oasx/config/constants.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/common/widgets/app_update_dialog.dart';
import 'package:oasx/service/app_update/app_version_utils.dart';
import 'package:oasx/service/app_update/installers/android_update_installer.dart';
import 'package:oasx/service/app_update/installers/app_update_installer.dart';
import 'package:oasx/service/app_update/installers/fallback_update_installer.dart';
import 'package:oasx/service/app_update/installers/windows_update_installer.dart';
import 'package:oasx/service/app_update/models/app_update_plan.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Owns app-release discovery, download, and install handoff.
class AppUpdateService extends GetxService {
  /// Stores the last successful release check timestamp.
  final GetStorage _storage = GetStorage();

  /// Tracks whether an in-app install flow is running.
  final RxBool isInstalling = false.obs;

  /// Suppresses automatic remote checks for one week.
  static const Duration _updateCheckInterval = Duration(days: 7);

  /// Checks for a new OASX release and opens the update dialog when found.
  Future<void> checkForUpdates({
    bool showTip = false,
    bool forceCheck = false,
  }) async {
    // if (!kReleaseMode || _shouldSkipRemoteCheck(forceCheck)) {
    //   return;
    // }
    final release = await ApiClient().getGithubRelease();
    if (!release.isValid) {
      return;
    }
    await _writeLastUpdateCheckAt();
    final currentVersion = await AppVersionUtils.getCurrentVersion();
    final latestVersion = release.version ?? 'v0.0.0';
    if (!AppVersionUtils.compareVersion(currentVersion, latestVersion)) {
      if (showTip) {
        Get.snackbar(I18n.tip.tr, I18n.noNewVersion.tr);
      }
      return;
    }
    final plan = await _createPlan(release, currentVersion);
    Get.dialog(AppUpdateDialog(plan: plan, service: this));
  }

  /// Opens the release page for the provided [release].
  Future<void> openReleasePage(GithubReleaseModel release) async {
    final releaseUrl = release.releasePageUrl ?? oasxRelease;
    await launchUrl(Uri.parse(releaseUrl));
  }

  /// Downloads the selected asset and starts the platform install handoff.
  Future<void> installUpdate(AppUpdatePlan plan) async {
    if (isInstalling.value || plan.asset == null || !plan.canInstallInApp) {
      return;
    }
    isInstalling.value = true;
    Get.snackbar(I18n.tip.tr, I18n.updateDownloading.tr);
    try {
      final package = await _downloadPackage(plan);
      final isValid = await _validatePackage(package);
      if (!isValid) {
        Get.snackbar(I18n.tip.tr, I18n.updateInvalidPackage.tr);
        return;
      }
      Get.snackbar(I18n.tip.tr, I18n.updatePreparing.tr);
      await _createInstaller().install(package);
      if (!PlatformUtils.isWindows) {
        Get.snackbar(I18n.tip.tr, I18n.updateInstallStarted.tr);
      }
    } catch (error) {
      final message = error.toString().contains('permission_required')
          ? I18n.updateAllowUnknownApps.tr
          : I18n.updateDownloadFailed.tr;
      Get.snackbar(I18n.tip.tr, message);
    } finally {
      isInstalling.value = false;
    }
  }

  /// Builds the update plan shown in the shared update dialog.
  Future<AppUpdatePlan> _createPlan(
    GithubReleaseModel release,
    String currentVersion,
  ) async {
    final installer = _createInstaller();
    final canInstallInApp = await installer.canInstallInApp();
    final asset = canInstallInApp ? await installer.selectAsset(release) : null;
    return AppUpdatePlan(
      currentVersion: currentVersion,
      release: release,
      asset: asset,
      canInstallInApp: canInstallInApp && asset != null,
      installActionKey: installer.installActionKey,
    );
  }

  /// Picks the installer implementation for the current platform.
  AppUpdateInstaller _createInstaller() {
    if (PlatformUtils.isWindows) {
      return const WindowsUpdateInstaller();
    }
    if (PlatformUtils.isAndroid) {
      return const AndroidUpdateInstaller();
    }
    return const FallbackUpdateInstaller();
  }

  /// Downloads the selected update package into a temporary directory.
  Future<DownloadedUpdatePackage> _downloadPackage(AppUpdatePlan plan) async {
    final asset = plan.asset!;
    final tempDirectory = await getTemporaryDirectory();
    final updateDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}oasx_updates${Platform.pathSeparator}${plan.release.version ?? 'latest'}',
    );
    await updateDirectory.create(recursive: true);
    final assetName = asset.name ?? 'oasx_update_package';
    final filePath =
        '${updateDirectory.path}${Platform.pathSeparator}$assetName';
    await _downloadToFile(asset.downloadUrl!, filePath);
    return DownloadedUpdatePackage(
      release: plan.release,
      asset: asset,
      filePath: filePath,
    );
  }

  /// Downloads a remote asset to [filePath].
  Future<void> _downloadToFile(String url, String filePath) async {
    final httpClient = HttpClient();
    IOSink? output;
    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('download_failed_${response.statusCode}');
      }
      output = File(filePath).openWrite();
      await response.forEach(output.add);
    } finally {
      await output?.close();
      httpClient.close();
    }
  }

  /// Validates the downloaded package checksum when GitHub exposes one.
  Future<bool> _validatePackage(DownloadedUpdatePackage package) async {
    final expectedDigest = _normalizeDigest(package.asset.digest);
    if (expectedDigest == null) {
      return true;
    }
    final actualDigest = await _computeSha256(package.filePath);
    return expectedDigest == actualDigest;
  }

  /// Computes a SHA-256 digest for the file at [filePath].
  Future<String> _computeSha256(String filePath) async {
    final fileBytes = await File(filePath).readAsBytes();
    final digest = sha256.convert(fileBytes);
    return digest.toString();
  }

  /// Normalizes GitHub digest strings such as `sha256:<hash>`.
  String? _normalizeDigest(String? digest) {
    if (digest == null || digest.trim().isEmpty) {
      return null;
    }
    return digest.split(':').last.trim().toLowerCase();
  }

  /// Returns true when the remote check should stay suppressed.
  bool _shouldSkipRemoteCheck(bool forceCheck) {
    if (forceCheck) {
      return false;
    }
    final lastCheckAt = _readLastUpdateCheckAt();
    if (lastCheckAt == null) {
      return false;
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (lastCheckAt > now) {
      return false;
    }
    return now - lastCheckAt < _updateCheckInterval.inMilliseconds;
  }

  /// Reads the last successful update check time from storage.
  int? _readLastUpdateCheckAt() {
    final raw = _storage.read(StorageKey.lastUpdateCheckAt.name);
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  /// Persists the current time as the last successful update check.
  Future<void> _writeLastUpdateCheckAt() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _storage.write(StorageKey.lastUpdateCheckAt.name, now);
  }
}
