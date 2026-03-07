part of settings;

class OasSettingsCard extends StatelessWidget {
  const OasSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      title: 'OAS${I18n.setting.tr}',
      items: [
        SettingItem(
          left: Text(I18n.notify_test.tr),
          right: const Icon(Icons.input_rounded),
          onTap: notifyTest,
        ),
        SettingItem(
          left: Text(I18n.auto_run_script.tr),
          right: const AutoScriptButton(),
        ),
        if (PlatformUtils.isDesktop)
          SettingItem(
            left: Text(I18n.setup_deploy.tr),
            right: const Icon(Icons.input_rounded),
            onTap: openDeploySetting,
          ),
        if (PlatformUtils.isDesktop)
          SettingItem(
            left: Text(I18n.auto_deploy.tr),
            right: const DeploySwitcher(),
          ),
        if (PlatformUtils.isDesktop)
          SettingItem(
            left: Text(I18n.auto_login_after_deploy.tr),
            right: const LoginAfterDeploySwitcher(),
          ),
        SettingItem(
          left: Text(I18n.updater.tr),
          right: const Icon(Icons.input_rounded),
          onTap: updater,
        ),
        SettingItem(
          left: Text(I18n.kill_oas_server.tr),
          right: const Icon(Icons.input_rounded),
          onTap: killServer,
        ),
      ],
    );
  }
}

void notifyTest() {
  Get.defaultDialog(
    title: I18n.notify_test.tr,
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

enum _LoginFieldType { address, username, password }

class _LoginInputField extends StatefulWidget {
  const _LoginInputField({required this.type});

  final _LoginFieldType type;

  @override
  State<_LoginInputField> createState() => _LoginInputFieldState();
}

class _LoginInputFieldState extends State<_LoginInputField> {
  late final TextEditingController _controller;
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = Get.find<SettingsController>();
    _controller = TextEditingController(text: _currentValue);
  }

  @override
  void didUpdateWidget(covariant _LoginInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _currentValue;
    if (_controller.text != current) {
      _controller.text = current;
    }
  }

  String get _currentValue {
    return switch (widget.type) {
      _LoginFieldType.address => _settingsController.address.value,
      _LoginFieldType.username => _settingsController.username.value,
      _LoginFieldType.password => _settingsController.password.value,
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final value = _currentValue;
      if (_controller.text != value) {
        _controller.text = value;
      }
      return SizedBox(
        width: 220,
        child: TextField(
          controller: _controller,
          obscureText: widget.type == _LoginFieldType.password,
          onChanged: (text) {
            switch (widget.type) {
              case _LoginFieldType.address:
                _settingsController.updateAddress(text);
                break;
              case _LoginFieldType.username:
                _settingsController.updateUsername(text);
                break;
              case _LoginFieldType.password:
                _settingsController.updatePassword(text);
                break;
            }
          },
        ),
      );
    });
  }
}

class AutoScriptButton extends StatelessWidget {
  const AutoScriptButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Get.defaultDialog(
          title: I18n.auto_run_script_list.tr,
          content: const SingleChildScrollView(
            child: AutoScriptDialogContent(),
          ).constrained(maxHeight: 250).card(),
        );
      },
      icon: const Icon(Icons.settings_rounded),
    );
  }
}

void updater() {
  final screenWidth = Get.width;
  final screenHeight = Get.height;
  final proportionalWidth = screenWidth * 0.8;
  final proportionalHeight = screenHeight * 0.7;
  const contentIdealMaxWidth = 700.0;
  final finalMaxWidth = min(contentIdealMaxWidth, proportionalWidth);
  final finalMaxHeight = proportionalHeight;

  Get.defaultDialog(
    title: I18n.updater.tr,
    content: const UpdaterView()
        .constrained(maxWidth: finalMaxWidth, maxHeight: finalMaxHeight),
  );
}

void killServer() {
  Get.defaultDialog(
    title: I18n.are_you_sure_kill.tr,
    onCancel: () {},
    onConfirm: () async {
      await Get.find<SettingsController>().killServer();
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    },
  );
}

class AutoScriptDialogContent extends StatelessWidget {
  const AutoScriptDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final scriptService = Get.find<ScriptService>();
    final scriptList = scriptService.scriptModelMap.keys.toList()..sort();
    return scriptList
        .map((item) {
          return Obx(() {
            return <Widget>[
              Expanded(
                child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Checkbox(
                value: scriptService.autoScriptList.contains(item),
                onChanged: (nv) => scriptService.updateAutoScript(item, nv),
              ),
            ]
                .toRow(mainAxisAlignment: MainAxisAlignment.spaceBetween)
                .paddingSymmetric(vertical: 4, horizontal: 8);
          });
        })
        .toList()
        .toColumn(mainAxisSize: MainAxisSize.min);
  }
}
