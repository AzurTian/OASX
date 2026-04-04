import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/widgets/config_state_indicator.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/modules/home/widgets/task_catalog_panel.dart';
import 'package:oasx/modules/home/widgets/task_status_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

class ActiveConfigPanel extends StatelessWidget {
  const ActiveConfigPanel({
    super.key,
    required this.controller,
    required this.layoutMode,
    required this.onChangeTab,
    required this.onOpenTask,
    required this.onTogglePower,
    required this.onRenameScript,
    required this.onDeleteScript,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    this.onBackToScripts,
  });

  final HomeDashboardController controller;
  final HomeWorkbenchLayoutMode layoutMode;
  final Future<void> Function(HomeWorkbenchTab tab) onChangeTab;
  final Future<void> Function(
    String taskName,
    HomeTaskParameterEntrySource source,
  ) onOpenTask;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;
  final Future<void> Function(String scriptName) onRenameScript;
  final Future<void> Function(String scriptName) onDeleteScript;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final VoidCallback? onBackToScripts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          final script = controller.activeScriptModel;
          final currentTab = controller.displayedWorkbenchTabFor(layoutMode);
          final tabs = controller.workbenchTabsFor(layoutMode);
          if (script == null) {
            return Center(child: Text(I18n.homeNoScriptSelected.tr));
          }
          final isRunning = script.state.value == ScriptState.running;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBackToScripts != null)
                    IconButton(
                      tooltip: I18n.scriptList.tr,
                      onPressed: onBackToScripts,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Text(
                      script.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  ConfigStateIndicator(
                    state: controller.scriptStateFor(script),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: isRunning ? I18n.stop.tr : I18n.run.tr,
                    onPressed: () => onTogglePower(script.name, !isRunning),
                    icon: const Icon(Icons.power_settings_new_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tabs
                    .map(
                      (tab) => ChoiceChip(
                        label: Text(_tabLabel(tab)),
                        showCheckmark: false,
                        selected: currentTab == tab,
                        onSelected: (_) => onChangeTab(tab),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildTabContent(script, currentTab)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(ScriptModel script, HomeWorkbenchTab currentTab) {
    return switch (currentTab) {
      HomeWorkbenchTab.status => TaskStatusPanel(
          controller: controller,
          scriptModel: script,
          canQuickScheduleTask: (taskName) =>
              controller.canQuickScheduleTask(script, taskName),
          onSetNextRun: onSetNextRun,
          onQuickRun: onQuickRun,
          onQuickWait: onQuickWait,
          onEditTask: (taskName) =>
              onOpenTask(taskName, HomeTaskParameterEntrySource.overview),
        ),
      HomeWorkbenchTab.tasks => TaskCatalogPanel(
          controller: controller,
          scriptModel: script,
          onOpenTask: (taskName) =>
              onOpenTask(taskName, HomeTaskParameterEntrySource.tasks),
          onQuickRun: onQuickRun,
          onQuickWait: onQuickWait,
        ),
      HomeWorkbenchTab.stats => const ScriptStatisticsPanel(),
      HomeWorkbenchTab.logs => LogCenterPanel(scriptName: script.name),
    };
  }

  String _tabLabel(HomeWorkbenchTab value) {
    return switch (value) {
      HomeWorkbenchTab.status => I18n.overview.tr,
      HomeWorkbenchTab.tasks => I18n.homeTasksTab.tr,
      HomeWorkbenchTab.stats => I18n.homeStatsTab.tr,
      HomeWorkbenchTab.logs => I18n.log.tr,
    };
  }
}
