library settings;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:oasx/config/global.dart';
import 'package:oasx/controller/home/home_dashboard_controller.dart';
import 'package:oasx/controller/settings.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/window_service.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/views/home/tool_view.dart';
import 'package:oasx/views/home/updater_view.dart';
import 'package:oasx/views/settings/widgets/setting_card.dart';
import 'package:oasx/views/settings/widgets/setting_item.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/utils/platform_utils.dart';

part 'oas_card.dart';
part 'system_card.dart';
part 'user_card.dart';

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
      navTitleBuilder: () => I18n.user_setting.tr,
      cardBuilder: () => const UserSettingsCard(),
    ),
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => I18n.system_setting.tr,
      cardBuilder: () => const SystemSettingsCard(),
    ),
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => 'OAS${I18n.setting.tr}',
      cardBuilder: () => const OasSettingsCard(),
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

  void _handleLeaveSettings() {
    if (_hasHandledLeave) {
      return;
    }
    _hasHandledLeave = true;
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
    unawaited(
      Get.find<HomeDashboardController>().refreshAfterSettingsChanged(),
    );
  }

  void _handleScroll() {
    if (_isAutoScrolling || _lockSelectionToClickedNav || !mounted) return;
    _syncSelectedSectionByViewport();
  }

  void _syncSelectedSectionByViewport() {
    final sectionIndex = _findCurrentSectionIndex();
    if (sectionIndex == _selectedSectionIndex) return;
    setState(() => _selectedSectionIndex = sectionIndex);
  }

  int? _findCurrentSectionIndex() {
    final viewportContext = _scrollViewKey.currentContext;
    if (viewportContext == null) return _selectedSectionIndex;

    final viewportRenderObject = viewportContext.findRenderObject();
    if (viewportRenderObject is! RenderBox || !viewportRenderObject.hasSize) {
      return _selectedSectionIndex;
    }

    final viewportTop = viewportRenderObject.localToGlobal(Offset.zero).dy;
    int? currentSectionIndex;
    var bestDistance = double.infinity;

    for (var index = 0; index < _sections.length; index++) {
      final sectionContext = _sections[index].key.currentContext;
      if (sectionContext == null) continue;
      final sectionRenderObject = sectionContext.findRenderObject();
      if (sectionRenderObject is! RenderBox || !sectionRenderObject.hasSize) {
        continue;
      }

      final sectionTop =
          sectionRenderObject.localToGlobal(Offset.zero).dy - viewportTop;
      final distance = sectionTop.abs();
      if (distance <= _topAlignmentTolerance && distance < bestDistance) {
        bestDistance = distance;
        currentSectionIndex = index;
      }
    }

    return currentSectionIndex;
  }

  Future<void> _scrollToSection(int index) async {
    if (index < 0 || index >= _sections.length) return;

    final targetContext = _sections[index].key.currentContext;
    if (targetContext == null) return;

    setState(() {
      _selectedSectionIndex = index;
      _lockSelectionToClickedNav = true;
    });

    _isAutoScrolling = true;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
    _isAutoScrolling = false;
  }

  Widget _buildSettingList() {
    return Scrollbar(
      controller: _scrollController,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (_isAutoScrolling || !mounted) return false;
          if (notification.direction != ScrollDirection.idle &&
              _lockSelectionToClickedNav) {
            setState(() => _lockSelectionToClickedNav = false);
          }
          return false;
        },
        child: SingleChildScrollView(
          key: _scrollViewKey,
          controller: _scrollController,
          child: Column(
            children: _sections
                .map(
                  (section) => Container(
                    key: section.key,
                    margin: const EdgeInsets.only(bottom: _layoutSpacing),
                    child: section.cardBuilder(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryNav() {
    return SizedBox(
      width: _navWidth,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_sections.length, (index) {
              final isSelected = index == _selectedSectionIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _scrollToSection(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.38)
                          : Colors.transparent,
                    ),
                    child: Text(
                      _sections[index].navTitleBuilder(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
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

class _SettingsSection {
  _SettingsSection({
    required this.key,
    required this.navTitleBuilder,
    required this.cardBuilder,
  });

  final GlobalKey key;
  final String Function() navTitleBuilder;
  final Widget Function() cardBuilder;
}
