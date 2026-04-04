import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/api/github_release_model.dart';
import 'package:oasx/config/constants.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/common/widgets/app_update_dialog.dart';
import 'package:oasx/service/app_update/app_update_progress_formatter.dart';
import 'package:oasx/service/app_update/app_version_utils.dart';
import 'package:oasx/service/app_update/installers/android_update_installer.dart';
import 'package:oasx/service/app_update/installers/app_update_installer.dart';
import 'package:oasx/service/app_update/installers/fallback_update_installer.dart';
import 'package:oasx/service/app_update/installers/windows_update_installer.dart';
import 'package:oasx/service/app_update/models/app_update_plan.dart';
import 'package:oasx/service/app_update/update_package_io.dart';
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

  /// Tracks whether a release check is currently running.
  final RxBool isCheckingForUpdates = false.obs;

  /// Tracks the current download progress ratio.
  final RxDouble downloadProgress = (-1.0).obs;

  /// Tracks the current download progress label.
  final RxString downloadProgressLabel = ''.obs;

  UpdateDownloadSession? _activeDownloadSession;

  /// Suppresses automatic remote checks for one week.
  static const Duration _updateCheckInterval = Duration(days: 7);

  /// Checks for a new OASX release and opens the update dialog when found.
  Future<void> checkForUpdates({
    bool showTip = false,
    bool forceCheck = false,
  }) async {
    if (isCheckingForUpdates.value) {
      return;
    }
    isCheckingForUpdates.value = true;
    try {
      // if (!kReleaseMode || _shouldSkipRemoteCheck(forceCheck)) {
      //   return;
      // }
      final releaseResult = await _fetchLatestReleaseResult();
      final release = releaseResult.data;
      if (!releaseResult.isSuccess || release == null || !release.isValid) {
        if (showTip) {
          Get.snackbar(
              I18n.tip.tr, _buildUpdateCheckFailureMessage(releaseResult));
        }
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
      Get.dialog(AppUpdateDialog(plan: plan, service: this))
          .whenComplete(handleUpdateDialogClosed);
    } finally {
      isCheckingForUpdates.value = false;
    }
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
    _resetDownloadProgress();
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
      if (_isDownloadCancelled(error)) {
        return;
      }
      final message = error.toString().contains('permission_required')
          ? I18n.updateAllowUnknownApps.tr
          : I18n.updateDownloadFailed.tr;
      Get.snackbar(I18n.tip.tr, message);
    } finally {
      _activeDownloadSession = null;
      isInstalling.value = false;
    }
  }

  /// Cancels any active download and clears dialog state when the dialog closes.
  void handleUpdateDialogClosed() {
    _activeDownloadSession?.cancel();
    _activeDownloadSession = null;
    isInstalling.value = false;
    _resetDownloadProgress();
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
    final session = UpdateDownloadSession();
    _activeDownloadSession = session;
    final tempDirectory = await getTemporaryDirectory();
    final updateDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}oasx_updates${Platform.pathSeparator}${plan.release.version ?? 'latest'}',
    );
    await updateDirectory.create(recursive: true);
    final assetName = asset.name ?? 'oasx_update_package';
    final filePath =
        '${updateDirectory.path}${Platform.pathSeparator}$assetName';
    await UpdatePackageIo.downloadToFile(
      asset.downloadUrl!,
      filePath,
      proxyUrl: _readProxyUrl(),
      session: session,
      onProgress: _updateDownloadProgress,
    );
    return DownloadedUpdatePackage(
      release: plan.release,
      asset: asset,
      filePath: filePath,
    );
  }

  /// Validates the downloaded package checksum when GitHub exposes one.
  Future<bool> _validatePackage(DownloadedUpdatePackage package) async {
    final expectedDigest =
        UpdatePackageIo.normalizeDigest(package.asset.digest);
    if (expectedDigest == null) {
      return true;
    }
    final actualDigest = await UpdatePackageIo.computeSha256(package.filePath);
    return expectedDigest == actualDigest;
  }

  /// Updates the shared progress state for the download dialog.
  void _updateDownloadProgress(int receivedBytes, int totalBytes) {
    downloadProgress.value =
        totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : -1;
    downloadProgressLabel.value = AppUpdateProgressFormatter.formatProgress(
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
    );
  }

  /// Clears the shared progress state before a new install flow.
  void _resetDownloadProgress() {
    downloadProgress.value = -1;
    downloadProgressLabel.value = '';
  }

  /// Returns true when the thrown [error] indicates a user-cancelled download.
  bool _isDownloadCancelled(Object error) {
    return error is UpdateDownloadCancelledException;
  }

  /// Builds the snackbar message shown when a manual update check fails.
  String _buildUpdateCheckFailureMessage(
    ApiResult<GithubReleaseModel> releaseResult,
  ) {
    final error = releaseResult.error?.trim() ?? '';
    final code = releaseResult.code;
    if (code != null && error.isNotEmpty) {
      return '${I18n.updateCheckFailed.tr} ($code): $error';
    }
    if (code != null) {
      return '${I18n.updateCheckFailed.tr} ($code)';
    }
    if (error.isNotEmpty) {
      return '${I18n.updateCheckFailed.tr}: $error';
    }
    return I18n.updateCheckFailed.tr;
  }

  /// Fetches the latest release through proxy when configured, otherwise direct.
  Future<ApiResult<GithubReleaseModel>> _fetchLatestReleaseResult() async {
    final proxyUrl = _readProxyUrl();
    if (proxyUrl.isEmpty) {
      return ApiClient().getGithubReleaseResult();
    }
    try {
      final json = await UpdatePackageIo.fetchJsonMap(
        updateUrlGithub,
        proxyUrl: proxyUrl,
      );
      final release = GithubReleaseModel.fromJson(json);
      return ApiResult<GithubReleaseModel>.success(release);
    } catch (error) {
      final message = error is HttpException ? error.message : error.toString();
      return ApiResult<GithubReleaseModel>.failure(message);
    }
  }

  /// Returns true when the remote check should stay suppressed.
  // ignore: unused_element
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

  /// Reads the optional update proxy URL from settings storage.
  String _readProxyUrl() {
    final raw = _storage.read(StorageKey.updateProxyUrl.name);
    return raw is String ? raw.trim() : '';
  }
}
