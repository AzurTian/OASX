import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/controller/home/home_dashboard_controller.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/views/common/add_config_dialog.dart';
import 'package:oasx/views/home/widgets/home_constants.dart';
import 'package:oasx/views/home/widgets/home_overview_header.dart';
import 'package:oasx/views/home/widgets/home_script_grid.dart';
import 'package:oasx/views/home/widgets/home_task_settings_dialog.dart';
import 'package:oasx/views/layout/appbar.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.standalone = true});

  final bool standalone;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final scriptService = Get.find<ScriptService>();
  final controller = Get.find<HomeDashboardController>();
  bool _isAddingScript = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      checkUpdate();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.checkStartupConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Stack(
        children: [
          _buildDashboardBody(),
          Obx(() {
            final message = controller.startupLoadingMessage.value;
            if (message.isEmpty) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.25),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        message.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );

    if (!widget.standalone) {
      return body;
    }

    return Scaffold(
      appBar: buildPlatformAppBar(context, routePath: '/home'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/settings'),
        child: const Icon(Icons.settings_rounded),
      ),
      body: body,
    );
  }

  Widget _buildDashboardBody() {
    return Column(
      children: [
        Obx(() => HomeOverviewHeader(
              scriptService: scriptService,
              loadingAddScript: _isAddingScript,
              onAddScriptTap: _onAddScriptCardTap,
              isLinkModeEnabled: controller.isLinkModeEnabled.value,
              onToggleLinkMode: controller.toggleLinkMode,
            )),
        Expanded(
          child: Obx(() {
            if (controller.startupLoadingMessage.value.isNotEmpty) {
              return const SizedBox.expand();
            }
            final scripts = _orderedScripts();
            if (controller.isStartupConnectionFailed.value) {
              return _buildConnectionFailedView();
            }
            if (scripts.isEmpty) {
              return _buildEmptyScriptsView();
            }
            return HomeScriptGrid(
              scripts: scripts,
              scriptService: scriptService,
              onOpenLog: _openLogPage,
              isLinkModeEnabled: controller.isLinkModeEnabled.value,
              linkedScripts: controller.validLinkedScripts,
              onLinkedChanged: controller.setScriptLinked,
              onToggleScriptPower: _toggleScriptPower,
              onSetTaskArgument: _setTaskArgument,
              onOpenTaskSettings: _openTaskSettings,
              bottomReservedSpace:
                  widget.standalone ? kHomeSettingsFabReservedSpace : 0,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildConnectionFailedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              if (controller.isStartupChecking.value) {
                return const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                );
              }
              return IconButton.filled(
                onPressed: controller.retryStartupConnection,
                icon: const Icon(Icons.refresh_rounded),
                iconSize: 34,
                tooltip: I18n.home_connection_retry_action.tr,
              );
            }),
            const SizedBox(height: 12),
            Text(
              I18n.home_connection_retry_hint.tr,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScriptsView() {
    return Center(
      child: Text(
        I18n.home_empty_script_hint.tr,
        textAlign: TextAlign.center,
      ),
    );
  }

  List<ScriptModel> _orderedScripts() {
    final orderedNames = scriptService.scriptOrderList;
    final scriptMap = scriptService.scriptModelMap;
    final orderedScripts = <ScriptModel>[];
    for (final name in orderedNames) {
      final model = scriptMap[name];
      if (model != null) {
        orderedScripts.add(model);
      }
    }
    return orderedScripts;
  }

  Future<void> _onAddScriptCardTap() async {
    if (_isAddingScript) {
      return;
    }
    await showAddConfigDialog(
      context,
      onSubmitting: () {
        if (!mounted) return;
        setState(() {
          _isAddingScript = true;
        });
      },
      onSubmitDone: () {
        if (!mounted) return;
        setState(() {
          _isAddingScript = false;
        });
      },
    );
  }

  void _openLogPage(String scriptName) {
    Get.toNamed('/overview', parameters: {'script': scriptName});
  }

  Future<void> _toggleScriptPower(String scriptName, bool enable) async {
    await controller.applyLinkedPowerToggle(
      sourceScript: scriptName,
      enable: enable,
    );
  }

  Future<bool> _setTaskArgument(
    String scriptName,
    String taskName,
    String group,
    String argument,
    String type,
    dynamic value,
  ) async {
    return controller.applyLinkedSetArgument(
      config: scriptName,
      task: taskName,
      group: group,
      argument: argument,
      type: type,
      value: value,
    );
  }

  void _openTaskSettings(String scriptName, String taskName) {
    HomeTaskSettingsDialog.show(
      scriptName: scriptName,
      taskName: taskName,
      setArgumentOverride: (config, task, group, argument, type, value) {
        unawaited(controller.applyLinkedSetArgument(
          config: config,
          task: task,
          group: group,
          argument: argument,
          type: type,
          value: value,
        ));
      },
    );
  }
}
