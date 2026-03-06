import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/home/widgets/home_constants.dart';
import 'package:oasx/views/home/widgets/home_task_summary.dart';

enum HomeScriptMenuAction {
  rename,
  delete,
}

class HomeScriptCard extends StatelessWidget {
  const HomeScriptCard({
    super.key,
    required this.scriptModel,
    required this.scriptService,
    required this.onOpenLog,
    required this.onMenuSelected,
    required this.taskListHeight,
    required this.onTaskListTap,
  });

  final ScriptModel scriptModel;
  final ScriptService scriptService;
  final VoidCallback onOpenLog;
  final ValueChanged<HomeScriptMenuAction> onMenuSelected;
  final double taskListHeight;
  final VoidCallback onTaskListTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: homeScriptCardHeight(taskListHeight),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Obx(() {
            final state = scriptModel.state.value;
            final isRunning = state == ScriptState.running;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: I18n.log.tr,
                      onPressed: onOpenLog,
                      icon: const Icon(Icons.article_outlined),
                    ),
                    Expanded(
                      child: Text(
                        scriptModel.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).paddingSymmetric(vertical: 3, horizontal: 4),
                    ),
                    _ScriptStateIndicator(state: state),
                    IconButton(
                      tooltip: isRunning ? I18n.stopped.tr : I18n.running.tr,
                      onPressed: () async {
                        if (isRunning) {
                          await scriptService.stopScript(scriptModel.name);
                        } else {
                          await scriptService.startScript(scriptModel.name);
                        }
                      },
                      icon: const Icon(Icons.power_settings_new_rounded),
                      isSelected: isRunning,
                    ),
                    PopupMenuButton<HomeScriptMenuAction>(
                      tooltip: I18n.setting.tr,
                      onSelected: onMenuSelected,
                      itemBuilder: (context) => [
                        PopupMenuItem<HomeScriptMenuAction>(
                          value: HomeScriptMenuAction.rename,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit, size: 18),
                              const SizedBox(width: 4),
                              Text(I18n.rename.tr),
                            ],
                          ),
                        ),
                        PopupMenuItem<HomeScriptMenuAction>(
                          value: HomeScriptMenuAction.delete,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              const SizedBox(width: 4),
                              Text(I18n.delete.tr),
                            ],
                          ),
                        ),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.settings_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 14),
                SizedBox(
                  height: taskListHeight,
                  child: HomeTaskSummary(
                    scriptModel: scriptModel,
                    onTapList: onTaskListTap,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ScriptStateIndicator extends StatelessWidget {
  const _ScriptStateIndicator({required this.state});

  final ScriptState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: switch (state) {
        ScriptState.running => const SpinKitChasingDots(
            color: Colors.green,
            size: 22,
          ),
        ScriptState.inactive =>
          const Icon(Icons.donut_large, size: 24, color: Colors.grey),
        ScriptState.warning =>
          const SpinKitDoubleBounce(color: Colors.orange, size: 24),
        ScriptState.updating => const Icon(
            Icons.browser_updated_rounded,
            size: 24,
            color: Colors.blue,
          ),
      },
    );
  }
}
