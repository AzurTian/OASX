part of settings;

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
          title: I18n.autoRunScriptList.tr,
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
  final settingsController = Get.find<SettingsController>();
  final isKilling = false.obs;

  Get.dialog(
    Obx(() {
      final killing = isKilling.value;
      return AlertDialog(
        title: Text(I18n.areYouSureKill.tr),
        actions: [
          TextButton(
            onPressed: killing
                ? null
                : () {
                    if (Get.isDialogOpen ?? false) {
                      Get.back();
                    }
                  },
            child: Text(I18n.cancel.tr),
          ),
          FilledButton(
            onPressed: killing
                ? null
                : () async {
                    isKilling.value = true;
                    var closedByTimeout = false;
                    final autoCloseTimer = Timer(const Duration(seconds: 5), () {
                      closedByTimeout = true;
                      if (Get.isDialogOpen ?? false) {
                        Get.back();
                      }
                    });
                    try {
                      final success = await settingsController.killServer();
                      if (success) {
                        if (!closedByTimeout && (Get.isDialogOpen ?? false)) {
                          Get.back();
                        }
                        return;
                      }
                      if (!closedByTimeout) {
                        isKilling.value = false;
                      }
                    } finally {
                      autoCloseTimer.cancel();
                    }
                  },
            child: killing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(I18n.confirm.tr),
          ),
        ],
      );
    }),
    barrierDismissible: false,
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
