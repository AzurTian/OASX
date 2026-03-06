import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/home/widgets/auto_scroll_text.dart';

enum HomeTaskType {
  none,
  running,
  pending,
  waiting,
}

class HomeTaskData {
  const HomeTaskData({
    required this.type,
    required this.name,
    this.time = '',
  });

  final HomeTaskType type;
  final String name;
  final String time;
}

class HomeTaskSummary extends StatelessWidget {
  const HomeTaskSummary({super.key, required this.scriptModel});

  final ScriptModel scriptModel;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final task = _pickTask();
      if (task.type == HomeTaskType.none) {
        return Text(
          I18n.home_unconfigured_task.tr,
          style: Theme.of(context).textTheme.bodyLarge,
        );
      }

      return Row(
        children: [
          _TaskTypeIndicator(type: task.type),
          const SizedBox(width: 8),
          Expanded(
            child: AutoScrollText(
              text: _buildTaskLine(task),
            ),
          ),
        ],
      );
    });
  }

  String _buildTaskLine(HomeTaskData task) {
    final taskName = task.name.tr;
    if (task.type == HomeTaskType.waiting && task.time.trim().isNotEmpty) {
      return '$taskName  ${task.time}';
    }
    return taskName;
  }

  HomeTaskData _pickTask() {
    final scriptState = scriptModel.state.value;
    final runningTask = scriptModel.runningTask.value;
    final runningName = runningTask.taskName.value.trim();
    if (scriptState == ScriptState.running && runningName.isNotEmpty) {
      return HomeTaskData(type: HomeTaskType.running, name: runningName);
    }

    final pending = scriptModel.pendingTaskList;
    if (pending.isNotEmpty) {
      final task = pending.first;
      return HomeTaskData(
        type: HomeTaskType.pending,
        name: task.taskName.value.trim(),
      );
    }

    final waiting = scriptModel.waitingTaskList;
    if (waiting.isNotEmpty) {
      final task = waiting.first;
      return HomeTaskData(
        type: HomeTaskType.waiting,
        name: task.taskName.value.trim(),
        time: task.nextRun.value.trim(),
      );
    }

    return const HomeTaskData(type: HomeTaskType.none, name: '');
  }
}

class _TaskTypeIndicator extends StatelessWidget {
  const _TaskTypeIndicator({required this.type});

  final HomeTaskType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      HomeTaskType.running =>
        const Icon(Icons.bolt_rounded, color: Colors.green, size: 20),
      HomeTaskType.pending =>
        const Icon(Icons.layers_rounded, color: Colors.orange, size: 20),
      HomeTaskType.waiting =>
        const Icon(Icons.schedule_rounded, color: Colors.blueGrey, size: 20),
      HomeTaskType.none =>
        const Icon(Icons.hourglass_empty_rounded, color: Colors.grey, size: 20),
    };
  }
}
