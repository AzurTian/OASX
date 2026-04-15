import 'package:get/get.dart';
import 'package:oasx/service/app_update/app_version_utils.dart';
import 'package:oasx/service/app_update_service.dart';

Future<String> getCurrentVersion() async {
  return AppVersionUtils.getCurrentVersion();
}

bool compareVersion(String current, String latest) {
  return AppVersionUtils.compareVersion(current, latest);
}

Future<void> checkUpdate({
  bool showTip = false,
  bool forceCheck = false,
}) async {
  if (!Get.isRegistered<AppUpdateService>()) {
    return;
  }
  await Get.find<AppUpdateService>().checkForUpdates(
    showTip: showTip,
    forceCheck: forceCheck,
  );
}
