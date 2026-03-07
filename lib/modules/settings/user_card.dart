part of settings;

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

