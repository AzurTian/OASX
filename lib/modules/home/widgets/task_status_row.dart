import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/common/models/config_drag_payload.dart';
import 'package:oasx/modules/common/widgets/drag_copy_feedback.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/widgets/split_scroll_row.dart';
import 'package:oasx/modules/home/widgets/task_status_swipe_container.dart';
import 'package:oasx/translation/i18n_content.dart';

part 'task_status_row_parts.dart';

/// Describes one task row rendered inside the overview task list.
class TaskStatusViewData {
  const TaskStatusViewData({
    required this.rowId,
    required this.name,
    required this.type,
    this.timeText = '',
  });

  final String rowId;
  final String name;
  final TaskStatusType type;
  final String timeText;
}

/// Defines the three task states rendered in the overview tab.
enum TaskStatusType {
  running,
  pending,
  waiting,
}

/// Renders one swipe-to-disable task row for the overview tab.
class TaskStatusRow extends StatelessWidget {
  const TaskStatusRow({
    super.key,
    required this.controller,
    required this.sourceScriptName,
    required this.task,
    required this.canQuickSchedule,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
    required this.onDisableTask,
    required this.onDismissed,
    required this.dragEnabled,
    required this.swipeEnabled,
    required this.activeDragPayload,
  });

  final HomeDashboardController controller;
  final String sourceScriptName;
  final TaskStatusViewData task;
  final bool canQuickSchedule;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;
  final Future<bool> Function(String taskName) onDisableTask;
  final ValueChanged<String> onDismissed;
  final bool dragEnabled;
  final bool swipeEnabled;
  final ConfigDragPayload? activeDragPayload;
  static const double _actionExtent = 132;

  @override
  Widget build(BuildContext context) {
    final rowBackground = _rowBackground(context);
    return TaskStatusSwipeContainer(
      enabled: swipeEnabled,
      onConfirmDismiss: () => onDisableTask(task.name),
      onDismissed: () => onDismissed(task.rowId),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _foregroundColor(context, rowBackground),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SplitScrollRow(
            minHeight: 40,
            trailingExtent: _actionExtent,
            trailingBackgroundColor: rowBackground,
            trailing: _TaskActionBar(
              onQuickRun: canQuickSchedule ? () => onQuickRun(task.name) : null,
              onQuickWait:
                  canQuickSchedule ? () => onQuickWait(task.name) : null,
              onEditTask: () => onEditTask(task.name),
            ),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TaskTypeIcon(type: task.type),
                const SizedBox(width: 10),
                _TaskMeta(
                  controller: controller,
                  sourceScriptName: sourceScriptName,
                  task: task,
                  onSetNextRun: onSetNextRun,
                  dragEnabled: dragEnabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Resolves the row background by task bucket.
  Color _rowBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (task.type) {
      TaskStatusType.running =>
        scheme.tertiaryContainer.withValues(alpha: 0.24),
      TaskStatusType.pending =>
        scheme.secondaryContainer.withValues(alpha: 0.2),
      TaskStatusType.waiting => scheme.surfaceContainerHigh,
    };
  }

  /// Resolves the highlighted foreground color during drag-copy sessions.
  Color _foregroundColor(BuildContext context, Color fallback) {
    final isDraggingTask = activeDragPayload?.matchesTask(
          sourceScriptName,
          task.name,
        ) ??
        false;
    if (!isDraggingTask) {
      return fallback;
    }
    return Theme.of(context)
        .colorScheme
        .primaryContainer
        .withValues(alpha: 0.42);
  }

  /// Resolves the row border tint by task bucket.
  Color _borderColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (task.type) {
      TaskStatusType.running => Colors.green.withValues(alpha: 0.28),
      TaskStatusType.pending => Colors.orange.withValues(alpha: 0.3),
      TaskStatusType.waiting => scheme.outlineVariant.withValues(alpha: 0.7),
    };
  }
}
