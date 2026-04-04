import 'package:oasx/api/github_release_model.dart';
import 'package:oasx/service/app_update/installers/app_update_installer.dart';
import 'package:oasx/service/app_update/models/app_update_plan.dart';

/// Provides a release-page-only fallback for unsupported platforms.
class FallbackUpdateInstaller implements AppUpdateInstaller {
  /// Creates a fallback installer.
  const FallbackUpdateInstaller();

  @override
  String get installActionKey => '';

  @override
  Future<bool> canInstallInApp() async {
    return false;
  }

  @override
  Future<GithubReleaseAssetModel?> selectAsset(
      GithubReleaseModel release) async {
    return null;
  }

  @override
  Future<void> install(DownloadedUpdatePackage package) async {}
}
