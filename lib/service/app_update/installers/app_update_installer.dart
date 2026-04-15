import 'package:oasx/api/github_release_model.dart';
import 'package:oasx/service/app_update/models/app_update_plan.dart';

/// Defines a platform-specific app update installer.
abstract class AppUpdateInstaller {
  /// I18n key for the primary install action.
  String get installActionKey;

  /// Returns true when the platform can install inside the app.
  Future<bool> canInstallInApp();

  /// Selects the preferred release asset for the current platform.
  Future<GithubReleaseAssetModel?> selectAsset(GithubReleaseModel release);

  /// Installs the downloaded update package.
  Future<void> install(DownloadedUpdatePackage package);
}
