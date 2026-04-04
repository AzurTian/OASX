import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_nb_net/flutter_net.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/constants.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class GithubVersionModel extends BaseNetModel {
  @override
  GithubVersionModel fromJson(Map<String, dynamic> json) {
    return GithubVersionModel.fromJson(json);
  }

  GithubVersionModel({
    this.version,
    this.body,
    this.updatedAt,
  });
  GithubVersionModel.fromJson(dynamic json) {
    version = json['tag_name'];
    body = json['body'];
    updatedAt = json['updated_at'];
  }

  String? version;
  String? body;
  String? updatedAt; // 长这样 2025-08-26T12:32:36Z
}

const Duration _updateCheckInterval = Duration(days: 7);
final GetStorage _updateCheckStorage = GetStorage();

bool compareVersion(String current, String latest) {
  current = current.contains('v') ? current.substring(1) : current;
  latest = latest.contains('v') ? latest.substring(1) : latest;
  List<String> currentNumbers = current.split('.');
  List<String> latestNumbers = latest.split('.');
  if (int.parse(currentNumbers[0]) < int.parse(latestNumbers[0])) {
    return true;
  }
  if (int.parse(currentNumbers[1]) < int.parse(latestNumbers[1])) {
    return true;
  }
  List<String> currentLastList = currentNumbers[2].split('-');
  List<String> latestLastList = latestNumbers[2].split('-');
  if (int.parse(currentLastList[0]) < int.parse(latestLastList[0])) {
    return true;
  }
  return false;
}

Future<String> getCurrentVersion() async {
  if (kReleaseMode) {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return 'v${packageInfo.version}'.split('-')[0];
  }
  return 'v0.0.1';
}

void showUpdateVersion(String content) {
  Get.dialog(Markdown(data: content));
}

int? _readLastUpdateCheckAt() {
  final raw = _updateCheckStorage.read(StorageKey.lastUpdateCheckAt.name);
  if (raw is int) {
    return raw;
  }
  if (raw is String) {
    return int.tryParse(raw);
  }
  return null;
}

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

bool _hasValidGithubVersion(GithubVersionModel model) {
  return (model.version ?? '').trim().isNotEmpty;
}

Future<void> _writeLastUpdateCheckAt() async {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  await _updateCheckStorage.write(StorageKey.lastUpdateCheckAt.name, now);
}

Future<void> checkUpdate({
  bool showTip = false,
  bool forceCheck = false,
}) async {
  if (!kReleaseMode) {
    return;
  }
  if (_shouldSkipRemoteCheck(forceCheck)) {
    return;
  }
  final githubVersionModel = await ApiClient().getGithubVersion();
  if (!_hasValidGithubVersion(githubVersionModel)) {
    if (showTip) {
      Get.snackbar(I18n.tip.tr, I18n.noNewVersion.tr);
    }
    return;
  }
  await _writeLastUpdateCheckAt();
  String currentVersion = await getCurrentVersion();
  String githubVersion = githubVersionModel.version ?? 'v0.0.0';
  debugPrint('currentVersion: $currentVersion, githubVersion: $githubVersion');
  String githubUpdateInfo = githubVersionModel.body ?? 'Something wrong';
  Widget goOasxRelease = TextButton(
      onPressed: () async => {await launchUrl(Uri.parse(oasxRelease))},
      child: Text(I18n.goOasxRelease.tr));
  if (compareVersion(currentVersion, githubVersion)) {
    Widget dialog = SingleChildScrollView(
            child: <Widget>[
      Text('${I18n.latestVersion.tr}: $githubVersion'),
      Text('${I18n.currentVersion.tr}: $currentVersion'),
      goOasxRelease,
      MarkdownBody(data: githubUpdateInfo),
    ].toColumn(crossAxisAlignment: CrossAxisAlignment.start))
        .constrained(height: 300, width: 300);
    Get.defaultDialog(title: I18n.findNewVersion.tr, content: dialog);
    return;
  }
  if (showTip) Get.snackbar(I18n.tip.tr, I18n.noNewVersion.tr);
}
