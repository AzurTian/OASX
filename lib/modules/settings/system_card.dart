import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/config/global.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/modules/settings/widgets/setting_card.dart';
import 'package:oasx/modules/settings/widgets/setting_item.dart';
import 'package:oasx/service/autostart_service.dart';
import 'package:oasx/service/app_update_service.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/window_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/utils/platform_utils.dart';

class SystemSettingsCard extends StatelessWidget {
  const SystemSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      title: I18n.systemSetting.tr,
      items: [
        SettingItem(
          left: Text(I18n.changeTheme.tr),
          right: const ThemeSwitcher(),
        ),
        SettingItem(
          left: Text(I18n.changeLanguage.tr),
          right: const LanguageToggle(),
        ),
        if (PlatformUtils.isDesktop)
          SettingItem(
            left: Text(I18n.rememberWindowPositionSize.tr),
            right: const WindowStateSwitch(),
          ),
        if (PlatformUtils.isDesktop)
          SettingItem(
            left: Row(
              children: [
                Text(I18n.minimizeToSystemTray.tr),
                Tooltip(
                  message: I18n.minimizeToSystemTrayHelp.tr,
                  child: const Icon(Icons.help_outline, size: 16),
                ).paddingOnly(left: 5),
              ],
            ),
            right: const SystemTraySwitch(),
          ),
        if (PlatformUtils.isDesktop)
          SettingItem(
            left: Row(
              children: [
                Text(I18n.launchAtStartup.tr),
                Tooltip(
                  message: I18n.launchAtStartupHelp.tr,
                  child: const Icon(Icons.help_outline, size: 16),
                ).paddingOnly(left: 5),
              ],
            ),
            right: const LaunchAtStartupSwitch(),
          ),
        if (!PlatformUtils.isWeb)
          SettingItem(
            left: Row(
              children: [
                Text(I18n.updateProxyUrl.tr),
                Tooltip(
                  message: I18n.updateProxyUrlHelp.tr,
                  child: const Icon(Icons.help_outline, size: 16),
                ).paddingOnly(left: 5),
              ],
            ),
            right: const UpdateProxyUrlField(),
          ),
        SettingItem(
          left: Text('${I18n.currentVersion.tr}: ${GlobalVar.version}'),
          right: PlatformUtils.isWeb
              ? const SizedBox.shrink()
              : const CheckUpdateButton(),
        ),
      ],
    );
  }
}

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Get.find<LocaleService>();
    return Obx(() {
      final isSelected = switch (localeService.language.value) {
        'zh-CN' => [true, false],
        'en-US' => [false, true],
        _ => [true, false],
      };
      return ToggleButtons(
        isSelected: isSelected,
        onPressed: (index) {
          localeService.switchLanguage(index == 0 ? 'zh-CN' : 'en-US');
        },
        borderRadius: BorderRadius.circular(10),
        children: [
          Text(I18n.zhCn.tr).paddingSymmetric(horizontal: 10),
          Text(I18n.enUs.tr).paddingSymmetric(horizontal: 10),
        ],
      ).constrained(maxHeight: 40);
    });
  }
}

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    return Obx(() {
      return IconButton(
        onPressed: themeService.switchTheme,
        icon: const Icon(Icons.light_mode),
        selectedIcon: const Icon(Icons.dark_mode),
        isSelected: themeService.isDarkMode,
      );
    });
  }
}

class WindowStateSwitch extends StatelessWidget {
  const WindowStateSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final windowService = Get.find<WindowService>();
    return Obx(() => Switch(
          value: windowService.enableWindowState.value,
          onChanged: windowService.updateWindowStateEnable,
        ));
  }
}

class SystemTraySwitch extends StatelessWidget {
  const SystemTraySwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final windowService = Get.find<WindowService>();
    return Obx(() => Switch(
          value: windowService.enableSystemTray.value,
          onChanged: windowService.updateSystemTrayEnable,
        ));
  }
}

class LaunchAtStartupSwitch extends StatelessWidget {
  const LaunchAtStartupSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final autoStartService = Get.find<AutoStartService>();
    return Obx(() => Switch(
          value: autoStartService.enableLaunchAtStartup.value,
          onChanged: autoStartService.isApplying.value
              ? null
              : autoStartService.updateLaunchAtStartupEnable,
        ));
  }
}

class UpdateProxyUrlField extends StatefulWidget {
  const UpdateProxyUrlField({super.key});

  @override
  State<UpdateProxyUrlField> createState() => _UpdateProxyUrlFieldState();
}

class _UpdateProxyUrlFieldState extends State<UpdateProxyUrlField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = Get.find<SettingsController>();
    _controller =
        TextEditingController(text: _settingsController.updateProxyUrl.value);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _syncTextController();
      return SizedBox(
        width: 220,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.url,
          scrollPadding: EdgeInsets.only(
            left: 12,
            top: 12,
            right: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'http://127.0.0.1:7897',
          ),
          onTapOutside:
              PlatformUtils.isWeb ? null : (_) => _focusNode.unfocus(),
          onEditingComplete:
              PlatformUtils.isWeb ? null : _focusNode.unfocus,
          onChanged: _settingsController.updateUpdateProxyUrl,
        ),
      );
    });
  }

  void _syncTextController() {
    if (_focusNode.hasFocus) {
      return;
    }
    final current = _settingsController.updateProxyUrl.value;
    if (_controller.text == current) {
      return;
    }
    _controller.value = TextEditingValue(
      text: current,
      selection: TextSelection.collapsed(offset: current.length),
    );
  }
}

class CheckUpdateButton extends StatelessWidget {
  const CheckUpdateButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appUpdateService = Get.find<AppUpdateService>();
    return Obx(() {
      return ElevatedButton(
        onPressed: appUpdateService.isCheckingForUpdates.value
            ? null
            : () async => await checkUpdate(
                  showTip: true,
                  forceCheck: true,
                ),
        child: appUpdateService.isCheckingForUpdates.value
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(I18n.executeUpdate.tr),
      );
    });
  }
}
