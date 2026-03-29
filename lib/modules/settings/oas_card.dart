import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/home/tool_view.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/modules/settings/oas_card_extra.dart';
import 'package:oasx/modules/settings/widgets/setting_card.dart';
import 'package:oasx/modules/settings/widgets/setting_item.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

class OasSettingsCard extends StatelessWidget {
  const OasSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      title: 'OAS${I18n.setting.tr}',
      items: [
        SettingItem(
          left: Text(I18n.notifyTest.tr),
          right: const Icon(Icons.input_rounded),
          onTap: notifyTest,
        ),
        SettingItem(
          left: Text(I18n.autoRunScript.tr),
          right: const AutoScriptButton(),
        ),
        if (PlatformUtils.isDesktop)
          SettingItem(
            left: Text(I18n.setupDeploy.tr),
            right: const Icon(Icons.input_rounded),
            onTap: openDeploySetting,
          ),
        if (PlatformUtils.isDesktop)
          SettingItem(
            left: Text(I18n.autoDeploy.tr),
            right: const DeploySwitcher(),
          ),
        if (PlatformUtils.isDesktop)
          SettingItem(
            left: Text(I18n.autoLoginAfterDeploy.tr),
            right: const LoginAfterDeploySwitcher(),
          ),
        SettingItem(
          left: Text(I18n.updater.tr),
          right: const Icon(Icons.input_rounded),
          onTap: updater,
        ),
        SettingItem(
          left: Text(I18n.killOasServer.tr),
          right: const Icon(Icons.input_rounded),
          onTap: killServer,
        ),
      ],
    );
  }
}

void notifyTest() {
  Get.defaultDialog(
    title: I18n.notifyTest.tr,
    content: const NotifyTest(),
  );
}

void openDeploySetting() {
  Get.toNamed('/server');
}

class DeploySwitcher extends StatelessWidget {
  const DeploySwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    return Obx(
      () => Switch(
        value: settingsController.autoDeploy.value,
        onChanged: (nv) => settingsController.updateAutoDeploy(nv),
      ),
    );
  }
}

class LoginAfterDeploySwitcher extends StatelessWidget {
  const LoginAfterDeploySwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    return Obx(
      () => Switch(
        value: controller.autoLoginAfterDeploy.value,
        onChanged: (nv) => controller.updateAutoLoginAfterDeploy(nv),
      ),
    );
  }
}
