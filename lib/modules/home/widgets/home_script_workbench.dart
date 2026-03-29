import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/home_dashboard_controller.dart';
import 'package:oasx/modules/home/home_script_actions.dart';
import 'package:oasx/modules/home/widgets/home_active_script_panel.dart';
import 'package:oasx/modules/home/widgets/home_log_center_panel.dart';
import 'package:oasx/modules/home/widgets/home_script_collection_panel.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';

class HomeScriptWorkbench extends StatelessWidget {
  const HomeScriptWorkbench({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutMode = resolveHomeWorkbenchLayoutMode(constraints.maxWidth);
        final collection = HomeScriptCollectionPanel(
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
        );
        final details = HomeActiveScriptPanel(
          controller: controller,
          layoutMode: layoutMode,
          onChangeTab: (tab) => _changeTab(context, tab),
          onOpenTask: (taskName) => _openTask(context, taskName),
          onTogglePower: (scriptName, enable) =>
              controller.applySelectionPowerToggle(sourceScript: scriptName, enable: enable),
          onRenameScript: (scriptName) => _renameScript(context, scriptName),
          onDeleteScript: (scriptName) => _deleteScript(context, scriptName),
          onQuickRun: (taskName) => _quickSchedule(taskName, true),
          onQuickWait: (taskName) => _quickSchedule(taskName, false),
          onBackToScripts: layoutMode == HomeWorkbenchLayoutMode.singlePane
              ? () => _showScriptListPage(context)
              : null,
        );
        final logs = Obx(
          () => HomeLogCenterPanel(
            scriptName: controller.activeScriptName.value,
          ),
        );
        if (layoutMode == HomeWorkbenchLayoutMode.threePane) {
          return Row(
            children: [
              SizedBox(width: kHomeWorkbenchScriptListWidth, child: collection),
              const SizedBox(width: kHomeWorkbenchPaneGap),
              Expanded(child: details),
              const SizedBox(width: kHomeWorkbenchPaneGap),
              Expanded(child: logs),
            ],
          );
        }
        if (layoutMode == HomeWorkbenchLayoutMode.twoPane) {
          return Row(
            children: [
              SizedBox(width: kHomeWorkbenchScriptListWidth, child: collection),
              const SizedBox(width: kHomeWorkbenchPaneGap),
              Expanded(child: details),
            ],
          );
        }
        return Obx(() {
          final showWorkspace =
              controller.workbenchPage.value == HomeWorkbenchPage.workspace &&
                  controller.activeScriptName.value.trim().isNotEmpty;
          return showWorkspace ? details : collection;
        });
      },
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

  Future<void> _openTask(BuildContext context, String taskName) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    controller.setActiveTask(taskName, openParams: true);
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

  Future<void> _renameScript(BuildContext context, String scriptName) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    await HomeScriptActions.showRenameDialog(
      scriptService: scriptService,
      oldName: scriptName,
    );
    controller.syncWorkspaceState();
  }

  Future<void> _deleteScript(BuildContext context, String scriptName) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    await HomeScriptActions.showDeleteDialog(
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
