import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/script_model.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/widgets/home_task_settings_dialog.dart';

part 'home_task_summary_types.dart';
part 'home_task_summary_row.dart';

class HomeTaskSummary extends StatelessWidget {
  const HomeTaskSummary({
    super.key,
    required this.scriptModel,
    this.onTapList,
    this.onSetTaskArgument,
    this.onOpenTaskSettings,
  });

  final ScriptModel scriptModel;
  final VoidCallback? onTapList;
  final HomeTaskArgumentSetter? onSetTaskArgument;
  final void Function(String scriptName, String taskName)? onOpenTaskSettings;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tasks = _pickTasks();
      if (tasks.isEmpty) {
        return Align(
          alignment: Alignment.center,
          child: Text(
            I18n.homeUnconfiguredTask.tr,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      }

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTapList,
        child: ListView.separated(
          primary: false,
          padding: EdgeInsets.zero,
          itemCount: tasks.length,
          separatorBuilder: (context, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _TaskLine(
            task: tasks[index],
            scriptState: scriptModel.state.value,
            onSetTaskArgument: onSetTaskArgument,
            onOpenTaskSettings: onOpenTaskSettings,
          ),
        ),
      );
    });
  }

  List<HomeTaskData> _pickTasks() {
    final result = <HomeTaskData>[];
    final runningTask = scriptModel.runningTask.value;
    final runningName = runningTask.taskName.value.trim();
    if (runningName.isNotEmpty) {
      result.add(
        HomeTaskData(
          type: HomeTaskType.running,
          scriptName: scriptModel.name,
          taskName: runningName,
        ),
      );
    }

    for (final pending in scriptModel.pendingTaskList) {
      final pendingName = pending.taskName.value.trim();
      if (pendingName.isEmpty) {
        continue;
      }
      result.add(
        HomeTaskData(
          type: HomeTaskType.pending,
          scriptName: scriptModel.name,
          taskName: pendingName,
          nextRun: pending.nextRun.value.trim(),
        ),
      );
    }

    for (final waiting in scriptModel.waitingTaskList) {
      final waitingName = waiting.taskName.value.trim();
      if (waitingName.isEmpty) {
        continue;
      }
      result.add(
        HomeTaskData(
          type: HomeTaskType.waiting,
          scriptName: scriptModel.name,
          taskName: waitingName,
          nextRun: waiting.nextRun.value.trim(),
        ),
      );
    }

    return result;
  }
}

