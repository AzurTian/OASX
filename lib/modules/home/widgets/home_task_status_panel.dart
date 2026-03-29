import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/script_model.dart';
import 'package:oasx/modules/home/widgets/home_split_scroll_row.dart';
import 'package:oasx/translation/i18n_content.dart';

class HomeTaskStatusPanel extends StatelessWidget {
  const HomeTaskStatusPanel({
    super.key,
    required this.scriptModel,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
  });

  final ScriptModel scriptModel;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tasks = _collectTasks();
      if (tasks.isEmpty) {
        return Center(child: Text(I18n.homeNoTask.tr));
      }
      return ListView.separated(
        key: const PageStorageKey<String>('home-task-status-list'),
        padding: EdgeInsets.zero,
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _StatusTaskRow(
          task: tasks[index],
          onQuickRun: onQuickRun,
          onQuickWait: onQuickWait,
          onEditTask: onEditTask,
        ),
      );
    });
  }

  List<_StatusTaskData> _collectTasks() {
    final result = <_StatusTaskData>[];
    final runningTask = scriptModel.runningTask.value;
    if (runningTask.taskName.value.trim().isNotEmpty) {
      result.add(
        _StatusTaskData(
          name: runningTask.taskName.value,
          type: _StatusTaskType.running,
        ),
      );
    }
    result.addAll(
      scriptModel.pendingTaskList
          .where((task) => task.taskName.value.trim().isNotEmpty)
          .map(
            (task) => _StatusTaskData(
              name: task.taskName.value,
              type: _StatusTaskType.pending,
              timeText: task.nextRun.value.trim(),
            ),
          ),
    );
    result.addAll(
      scriptModel.waitingTaskList
          .where((task) => task.taskName.value.trim().isNotEmpty)
          .map(
            (task) => _StatusTaskData(
              name: task.taskName.value,
              type: _StatusTaskType.waiting,
              timeText: task.nextRun.value.trim(),
            ),
          ),
    );
    return result;
  }
}

class _StatusTaskRow extends StatelessWidget {
  const _StatusTaskRow({
    required this.task,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
  });

  final _StatusTaskData task;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;
  static const _actionExtent = 132.0;
  static const _minRowHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final rowBackground = _backgroundColor(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: rowBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: HomeSplitScrollRow(
          minHeight: _minRowHeight,
          trailingExtent: _actionExtent,
          trailingBackgroundColor: rowBackground,
          trailing: _TaskActionBar(
            onQuickRun: () => onQuickRun(task.name),
            onQuickWait: () => onQuickWait(task.name),
            onEditTask: () => onEditTask(task.name),
          ),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TaskTypeIcon(type: task.type),
              const SizedBox(width: 10),
              _TaskMeta(task: task),
            ],
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (task.type) {
      _StatusTaskType.running => colorScheme.tertiaryContainer.withValues(alpha: 0.24),
      _StatusTaskType.pending => colorScheme.secondaryContainer.withValues(alpha: 0.2),
      _StatusTaskType.waiting => colorScheme.surfaceContainerHigh,
    };
  }

  Color _borderColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (task.type) {
      _StatusTaskType.running => Colors.green.withValues(alpha: 0.28),
      _StatusTaskType.pending => Colors.orange.withValues(alpha: 0.3),
      _StatusTaskType.waiting => colorScheme.outlineVariant.withValues(alpha: 0.7),
    };
  }
}

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({
    required this.task,
  });

  final _StatusTaskData task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          task.name.tr,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        if (task.timeText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            task.timeText,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ],
    );
  }
}

class _TaskTypeIcon extends StatelessWidget {
  const _TaskTypeIcon({
    required this.type,
  });

  final _StatusTaskType type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      _StatusTaskType.running => const Icon(Icons.bolt_rounded, color: Colors.green),
      _StatusTaskType.pending => const Icon(Icons.layers_rounded, color: Colors.orange),
      _StatusTaskType.waiting => const Icon(Icons.schedule_rounded, color: Colors.blueGrey),
    };
    return SizedBox(width: 28, height: 28, child: Center(child: icon));
  }
}

class _TaskActionBar extends StatelessWidget {
  const _TaskActionBar({
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
  });

  final VoidCallback onQuickRun;
  final VoidCallback onQuickWait;
  final VoidCallback onEditTask;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TaskActionIcon(
          icon: Icons.flash_on_rounded,
          tooltip: I18n.homeQuickRun.tr,
          onPressed: onQuickRun,
        ),
        _TaskActionIcon(
          icon: Icons.schedule_rounded,
          tooltip: I18n.homeQuickWait.tr,
          onPressed: onQuickWait,
        ),
        _TaskActionIcon(
          icon: Icons.tune_rounded,
          tooltip: I18n.homeOpenTaskParams.tr,
          onPressed: onEditTask,
        ),
      ],
    );
  }
}

class _TaskActionIcon extends StatelessWidget {
  const _TaskActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _StatusTaskData {
  const _StatusTaskData({
    required this.name,
    required this.type,
    this.timeText = '',
  });

  final String name;
  final _StatusTaskType type;
  final String timeText;
}

enum _StatusTaskType {
  running,
  pending,
  waiting,
}
