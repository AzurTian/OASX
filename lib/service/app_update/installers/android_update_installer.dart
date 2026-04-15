import 'package:flutter/services.dart';
import 'package:oasx/api/github_release_model.dart';
import 'package:oasx/service/app_update/installers/app_update_installer.dart';
import 'package:oasx/service/app_update/models/app_update_plan.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Hands Android updates to the system package installer.
class AndroidUpdateInstaller implements AppUpdateInstaller {
  /// Creates an Android update installer.
  const AndroidUpdateInstaller();

  /// Native channel used for ABI lookup and installer handoff.
  static const MethodChannel _channel = MethodChannel('oasx/app_update');

  @override
  String get installActionKey => I18n.downloadAndInstall;

  @override
  Future<bool> canInstallInApp() async {
    return true;
  }

  @override
  Future<GithubReleaseAssetModel?> selectAsset(
      GithubReleaseModel release) async {
    final assets = release.assets ?? const <GithubReleaseAssetModel>[];
    final supportedAbis =
        (await _channel.invokeListMethod<String>('supportedAbis') ??
                const <String>[])
            .map((abi) => abi.toLowerCase())
            .toList();
    GithubReleaseAssetModel? universalAsset;
    for (final asset in assets) {
      final name = (asset.name ?? '').toLowerCase();
      if (!name.endsWith('.apk')) {
        continue;
      }
      if (name.contains('universal')) {
        universalAsset = asset;
        continue;
      }
      final matched = supportedAbis.any(name.contains);
      if (matched) {
        return asset;
      }
    }
    return universalAsset;
  }

  @override
  Future<void> install(DownloadedUpdatePackage package) async {
    await _channel.invokeMethod<void>(
      'installApk',
      <String, String>{'path': package.filePath},
    );
  }
}
