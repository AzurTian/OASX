import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/args/args_view.dart';
import 'package:styled_widget/styled_widget.dart';

enum HomeTaskType {
  running,
  pending,
  waiting,
}

class HomeTaskData {
  const HomeTaskData({
    required this.type,
    required this.scriptName,
    required this.taskName,
    this.nextRun = '',
  });

  final HomeTaskType type;
  final String scriptName;
  final String taskName;
  final String nextRun;
}

class HomeTaskSummary extends StatelessWidget {
  const HomeTaskSummary({
    super.key,
    required this.scriptModel,
    this.onTapList,
  });

  final ScriptModel scriptModel;
  final VoidCallback? onTapList;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tasks = _pickTasks();
      if (tasks.isEmpty) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            I18n.home_unconfigured_task.tr,
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

class _TaskLine extends StatelessWidget {
  const _TaskLine({
    required this.task,
    required this.scriptState,
  });

  static const _rowHeight = 50.0;
  static const _buttonVerticalGap = 4.0;

  final HomeTaskData task;
  final ScriptState scriptState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelMedium = Theme.of(context).textTheme.labelMedium;
    final rowBackground = switch (task.type) {
      HomeTaskType.running =>
        colorScheme.tertiaryContainer.withValues(alpha: 0.24),
      HomeTaskType.pending =>
        colorScheme.secondaryContainer.withValues(alpha: 0.2),
      HomeTaskType.waiting => colorScheme.surfaceContainerHigh,
    };
    final rowBorder = switch (task.type) {
      HomeTaskType.running => Colors.green.withValues(alpha: 0.28),
      HomeTaskType.pending => Colors.orange.withValues(alpha: 0.3),
      HomeTaskType.waiting => colorScheme.outlineVariant.withValues(alpha: 0.7),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: rowBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rowBorder, width: 1),
      ),
      child: SizedBox(
        height: _rowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _rowHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.center,
                    child: _TaskTypeIndicator(
                      type: task.type,
                      scriptState: scriptState,
                      size: constraints.maxHeight - 15,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    task.taskName.tr,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.type != HomeTaskType.running)
                    DateTimePicker(
                      value: task.nextRun,
                      hoverStyle: labelMedium,
                      notHoverStyle: labelMedium,
                      onChange: (nv) async {
                        final ret = await Get.find<ArgsController>()
                            .updateScriptTaskNextRun(
                                task.scriptName, task.taskName, nv);
                        if (ret) {
                          Get.snackbar(I18n.setting_saved.tr, nv,
                              duration: const Duration(seconds: 1));
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 60,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _openTaskSettings(context),
                child: Center(
                  child: Text(
                    I18n.setting.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ).paddingSymmetric(vertical: _buttonVerticalGap),
          ],
        ).paddingSymmetric(horizontal: 5),
      ),
    );
  }

  void _openTaskSettings(BuildContext context) {
    final maxWidth = min(750.0, Get.width * 0.9);
    final maxHeight = Get.height * 0.7;
    final argsController = Get.find<ArgsController>();
    Get.defaultDialog(
      title: '${task.taskName.tr}${I18n.setting.tr}',
      content: FutureBuilder<void>(
        future: argsController.loadGroups(
          config: task.scriptName,
          task: task.taskName,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('${I18n.error.tr}: ${snapshot.error}');
          }
          return Args(
            scriptName: task.scriptName,
            taskName: task.taskName,
            groupDraggable: false,
          ).constrained(
            minWidth: maxWidth,
            minHeight: maxHeight,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          );
        },
      ),
    );
  }
}

class _TaskTypeIndicator extends StatelessWidget {
  const _TaskTypeIndicator({
    required this.type,
    required this.scriptState,
    required this.size,
  });

  final HomeTaskType type;
  final ScriptState scriptState;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      HomeTaskType.running => switch (scriptState) {
          ScriptState.running => Icon(
              Icons.bolt_rounded,
              color: Colors.green,
              size: size,
            ),
          ScriptState.warning => Icon(
              Icons.error_rounded,
              color: Colors.orange,
              size: size,
            ),
          ScriptState.inactive => Icon(
              Icons.bolt_outlined,
              color: Colors.grey,
              size: size,
            ),
          ScriptState.updating => Icon(
              Icons.bolt_outlined,
              color: Colors.blueGrey,
              size: size,
            ),
        },
      HomeTaskType.pending => Icon(
          Icons.layers_rounded,
          color: Colors.orange,
          size: size,
        ),
      HomeTaskType.waiting => Icon(
          Icons.schedule_rounded,
          color: Colors.blueGrey,
          size: size,
        ),
    };
  }
}
