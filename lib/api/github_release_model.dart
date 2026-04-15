import 'package:flutter_nb_net/flutter_net.dart';

/// Parses a single GitHub release asset used by the app updater.
class GithubReleaseAssetModel extends BaseNetModel {
  /// Creates an empty release asset model.
  GithubReleaseAssetModel({
    this.name,
    this.downloadUrl,
    this.size,
    this.digest,
    this.contentType,
  });

  /// Deserializes a GitHub release asset payload.
  GithubReleaseAssetModel.fromJson(dynamic json) {
    name = json['name'] as String?;
    downloadUrl = json['browser_download_url'] as String?;
    size = json['size'] as int?;
    digest = json['digest'] as String?;
    contentType = json['content_type'] as String?;
  }

  /// Asset file name.
  String? name;

  /// Browser-facing download URL.
  String? downloadUrl;

  /// Asset size in bytes.
  int? size;

  /// Optional GitHub digest string such as `sha256:<hash>`.
  String? digest;

  /// Server-reported content type.
  String? contentType;

  @override
  GithubReleaseAssetModel fromJson(Map<String, dynamic> json) {
    return GithubReleaseAssetModel.fromJson(json);
  }
}

/// Parses the GitHub latest release payload used by the app updater.
class GithubReleaseModel extends BaseNetModel {
  /// Creates an empty release model.
  GithubReleaseModel({
    this.version,
    this.body,
    this.updatedAt,
    this.publishedAt,
    this.releasePageUrl,
    this.assets,
  });

  /// Deserializes the GitHub latest release payload.
  GithubReleaseModel.fromJson(dynamic json) {
    version = json['tag_name'] as String?;
    body = json['body'] as String?;
    updatedAt = json['updated_at'] as String?;
    publishedAt = json['published_at'] as String?;
    releasePageUrl = json['html_url'] as String?;
    assets = (json['assets'] as List<dynamic>? ?? const [])
        .map(GithubReleaseAssetModel.fromJson)
        .toList();
  }

  /// Release tag name.
  String? version;

  /// Markdown release notes.
  String? body;

  /// API update timestamp.
  String? updatedAt;

  /// Release publish timestamp.
  String? publishedAt;

  /// GitHub release page.
  String? releasePageUrl;

  /// Published assets for the release.
  List<GithubReleaseAssetModel>? assets;

  /// Indicates whether the release contains the fields needed by the updater.
  bool get isValid {
    return (version ?? '').trim().isNotEmpty &&
        (releasePageUrl ?? '').trim().isNotEmpty;
  }

  @override
  GithubReleaseModel fromJson(Map<String, dynamic> json) {
    return GithubReleaseModel.fromJson(json);
  }
}
