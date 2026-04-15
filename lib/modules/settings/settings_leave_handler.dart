import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';

Future<void> handleSettingsLeaveEffect() async {
  if (!Get.isRegistered<SettingsController>()) {
    return;
  }
  final settingsController = Get.find<SettingsController>();
  if (!settingsController.consumeLoginConfigChanged()) {
    return;
  }
  if (!Get.isRegistered<HomeDashboardController>()) {
    return;
  }
  await Get.find<HomeDashboardController>().refreshAfterSettingsChanged();
}
