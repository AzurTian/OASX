part of settings;

class UserSettingsCard extends StatelessWidget {
  const UserSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      title: I18n.user_setting.tr,
      items: [
        SettingItem(
          left: Text(I18n.login_address.tr),
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
