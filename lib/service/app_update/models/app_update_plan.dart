import 'package:oasx/api/github_release_model.dart';

/// Holds the release and installer state for the update dialog.
class AppUpdatePlan {
  /// Creates a new update plan.
  AppUpdatePlan({
    required this.currentVersion,
    required this.release,
    required this.asset,
    required this.canInstallInApp,
    required this.installActionKey,
  });

  /// The local app version.
  final String currentVersion;

  /// The latest GitHub release.
  final GithubReleaseModel release;

  /// The selected platform asset, if available.
  final GithubReleaseAssetModel? asset;

  /// Whether the platform can install inside the app.
  final bool canInstallInApp;

  /// I18n key for the install action.
  final String installActionKey;
}

/// Holds a downloaded package path and its asset metadata.
class DownloadedUpdatePackage {
  /// Creates a downloaded update package reference.
  DownloadedUpdatePackage({
    required this.release,
    required this.asset,
    required this.filePath,
  });

  /// The source GitHub release.
  final GithubReleaseModel release;

  /// The selected platform asset.
  final GithubReleaseAssetModel asset;

  /// The local package path.
  final String filePath;
}
