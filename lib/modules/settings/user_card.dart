import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/modules/settings/widgets/setting_card.dart';
import 'package:oasx/modules/settings/widgets/setting_item.dart';
import 'package:oasx/translation/i18n_content.dart';

class UserSettingsCard extends StatelessWidget {
  const UserSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      title: I18n.userSetting.tr,
      items: [
        SettingItem(
          left: Text(I18n.loginAddress.tr),
          right: const _LoginInputField(type: _LoginFieldType.address),
        ),
        SettingItem(
          left: Text(I18n.username.tr),
          right: const _LoginInputField(type: _LoginFieldType.username),
        ),
        SettingItem(
          left: Text(I18n.password.tr),
          right: const _LoginInputField(type: _LoginFieldType.password),
        ),
      ],
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
  late final FocusNode _focusNode;
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = Get.find<SettingsController>();
    _controller = TextEditingController(text: _currentValue);
    _focusNode = FocusNode();
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
    _focusNode.dispose();
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
          focusNode: _focusNode,
          obscureText: widget.type == _LoginFieldType.password,
          scrollPadding: EdgeInsets.only(
            left: 12,
            top: 12,
            right: 12,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          textInputAction: TextInputAction.done,
          onTapOutside: (_) => _focusNode.unfocus(),
          onEditingComplete: _focusNode.unfocus,
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
