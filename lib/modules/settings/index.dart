library settings;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:oasx/config/global.dart';
import 'package:oasx/modules/home/controllers/home_dashboard_controller.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/service/autostart_service.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/window_service.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/modules/home/tool_view.dart';
import 'package:oasx/modules/home/updater_view.dart';
import 'package:oasx/modules/settings/widgets/setting_card.dart';
import 'package:oasx/modules/settings/widgets/setting_item.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/utils/platform_utils.dart';

part 'oas_card.dart';
part 'oas_card_extra.dart';
part 'system_card.dart';
part 'user_card.dart';
part 'settings_view_navigation.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static const double _layoutSpacing = 8.0;
  static const double _wideLayoutBreakpoint = 960.0;
  static const double _navWidth = 220.0;
  static const double _topAlignmentTolerance = 12.0;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  late final List<_SettingsSection> _sections = [
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => I18n.userSetting.tr,
      cardBuilder: () => const UserSettingsCard(),
    ),
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => 'OAS${I18n.setting.tr}',
      cardBuilder: () => const OasSettingsCard(),
    ),
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => I18n.systemSetting.tr,
      cardBuilder: () => const SystemSettingsCard(),
    ),
  ];

  int? _selectedSectionIndex;
  bool _isAutoScrolling = false;
  bool _lockSelectionToClickedNav = false;
  bool _hasHandledLeave = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSelectedSectionByViewport();
    });
  }

  @override
  void dispose() {
    _handleLeaveSettings();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformAppBar(context, routePath: '/settings'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideLayoutBreakpoint;
          final settingList = _buildSettingList();

          if (!isWide) {
            return settingList.paddingOnly(left: 8, right: 8, top: 8);
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrimaryNav(),
              const SizedBox(width: _layoutSpacing),
              Expanded(child: settingList),
            ],
          ).paddingOnly(left: 8, right: 8, top: 8);
        },
      ),
    );
  }
}




