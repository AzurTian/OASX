import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/config_actions.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/widgets/active_config_panel.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/home/widgets/config_collection_panel.dart';
import 'package:oasx/modules/home/widgets/home_workbench_body.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigWorkbench extends StatelessWidget {
  const ConfigWorkbench({
    super.key,
    required this.controller,
    required this.scriptService,
    required this.loadingAddScript,
    required this.refreshingScripts,
    required this.onAddScriptTap,
    required this.onRefreshScriptsTap,
  });

  final HomeDashboardController controller;
  final ScriptService scriptService;
  final bool loadingAddScript;
  final bool refreshingScripts;
  final VoidCallback onAddScriptTap;
  final VoidCallback onRefreshScriptsTap;

  @override
  Widget build(BuildContext context) {
    return HomeWorkbenchBody(
      controller: controller,
      collectionBuilder: (layoutMode) => ConfigCollectionPanel(
        controller: controller,
        fillHeight: true,
        loadingAddScript: loadingAddScript,
        refreshingScripts: refreshingScripts,
        onAddScriptTap: onAddScriptTap,
        onRefreshScriptsTap: onRefreshScriptsTap,
        onActivateScript: (scriptName) =>
            _activateScript(context, scriptName, layoutMode),
        onTogglePower: (scriptName, enable) =>
            controller.applySelectionPowerToggle(sourceScript: scriptName, enable: enable),
        onRenameScript: (scriptName) => _renameScript(context, scriptName),
        onDeleteScript: (scriptName) => _deleteScript(context, scriptName),
      ),
      detailsBuilder: (layoutMode) => ActiveConfigPanel(
        controller: controller,
        layoutMode: layoutMode,
        onChangeTab: (tab) => _changeTab(context, tab),
        onOpenTask: (taskName, source) =>
            _openTaskFromSource(context, taskName, source),
        onTogglePower: (scriptName, enable) =>
            controller.applySelectionPowerToggle(sourceScript: scriptName, enable: enable),
        onRenameScript: (scriptName) => _renameScript(context, scriptName),
        onDeleteScript: (scriptName) => _deleteScript(context, scriptName),
        onSetNextRun: _setTaskNextRun,
        onQuickRun: (taskName) => _quickSchedule(taskName, true),
        onQuickWait: (taskName) => _quickSchedule(taskName, false),
        onBackToScripts: layoutMode == HomeWorkbenchLayoutMode.singlePane
            ? () => _showScriptListPage(context)
            : null,
      ),
      logs: Obx(() {
        return LogCenterPanel(scriptName: controller.activeScriptName.value);
      }),
    );
  }

  Future<void> _activateScript(
    BuildContext context,
    String scriptName,
    HomeWorkbenchLayoutMode layoutMode,
  ) async {
    final argsController = Get.find<ArgsController>();
    if (!argsController.isDraftMode.value || !argsController.hasDraftChanges) {
      controller.setActiveScript(scriptName);
      if (layoutMode == HomeWorkbenchLayoutMode.singlePane) {
        controller.showWorkspacePage();
      }
      return;
    }
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    controller.setActiveScript(scriptName);
    if (layoutMode == HomeWorkbenchLayoutMode.singlePane) {
      controller.showWorkspacePage();
    }
  }

  Future<void> _changeTab(
    BuildContext context,
    HomeWorkbenchTab tab,
  ) async {
    if (controller.activeWorkbenchTab.value == tab) {
      return;
    }
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    controller.setActiveWorkbenchTabValue(tab);
  }

  Future<void> _showScriptListPage(BuildContext context) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    controller.showScriptListPage();
  }

  Future<void> _openTaskFromSource(
    BuildContext context,
    String taskName,
    HomeTaskParameterEntrySource source,
  ) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    controller.openTaskParameters(taskName, source: source);
  }

  Future<void> _quickSchedule(String taskName, bool runNow) async {
    final scriptName = controller.activeScriptName.value.trim();
    if (scriptName.isEmpty) {
      return;
    }
    final ret = await controller.quickScheduleTask(
      scriptName: scriptName,
      taskName: taskName,
      runNow: runNow,
    );
    if (ret) {
      Get.snackbar(I18n.success.tr, taskName.tr);
    }
  }

  Future<void> _setTaskNextRun(String taskName, String nextRun) async {
    final scriptName = controller.activeScriptName.value.trim();
    if (scriptName.isEmpty) {
      return;
    }
    final ret = await controller.updateTaskNextRun(
      scriptName: scriptName,
      taskName: taskName,
      nextRun: nextRun,
    );
    if (ret) {
      Get.snackbar(I18n.success.tr, taskName.tr);
    }
  }

  Future<void> _renameScript(BuildContext context, String scriptName) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    await ConfigActions.showRenameDialog(
      scriptService: scriptService,
      oldName: scriptName,
    );
    controller.syncWorkspaceState();
  }

  Future<void> _deleteScript(BuildContext context, String scriptName) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    await ConfigActions.showDeleteDialog(
      scriptService: scriptService,
      name: scriptName,
    );
    controller.syncWorkspaceState();
  }

  Future<bool> _confirmDiscardDraft(BuildContext context) async {
    final argsController = Get.find<ArgsController>();
    if (!argsController.isDraftMode.value || !argsController.hasDraftChanges) {
      return true;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(I18n.argsDiscardChanges.tr),
        content: Text(I18n.argsUnsavedPrompt.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(I18n.cancel.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(I18n.confirm.tr),
          ),
        ],
      ),
    );
    if (result != true) {
      return false;
    }
    await argsController.discardDraftChanges();
    return true;
  }
}

