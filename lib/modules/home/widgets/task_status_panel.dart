import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_status_row.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Renders the overview task list for the active config workbench.
class TaskStatusPanel extends StatefulWidget {
  const TaskStatusPanel({
    super.key,
    required this.controller,
    required this.scriptModel,
    required this.canQuickScheduleTask,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
  });

  final HomeDashboardController controller;
  final ScriptModel scriptModel;
  final bool Function(String taskName) canQuickScheduleTask;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;

  @override
  State<TaskStatusPanel> createState() => _TaskStatusPanelState();
}

class _TaskStatusPanelState extends State<TaskStatusPanel> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _hiddenTaskIds = <String>{};
  String _searchQuery = '';

  @override
  void didUpdateWidget(covariant TaskStatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptModel.name == widget.scriptModel.name) {
      return;
    }
    _clearSearchState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dragPayload = widget.controller.activeDragPayload.value;
      final rawTasks = _collectTasks(widget.scriptModel);
      _pruneHiddenTaskIds(rawTasks);
      final visibleTasks = rawTasks
          .where((task) => !_hiddenTaskIds.contains(task.rowId))
          .where(_matchesTaskQuery)
          .toList();
      return Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 12),
          Expanded(
            child: visibleTasks.isEmpty
                ? Center(child: Text(_emptyMessage))
                : ListView.separated(
                    key: const PageStorageKey<String>('home-task-status-list'),
                    padding: EdgeInsets.zero,
                    itemCount: visibleTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      return TaskStatusRow(
                        key: ValueKey(task.rowId),
                        controller: widget.controller,
                        sourceScriptName: widget.scriptModel.name,
                        task: task,
                        canQuickSchedule:
                            widget.canQuickScheduleTask(task.name),
                        onSetNextRun: widget.onSetNextRun,
                        onQuickRun: widget.onQuickRun,
                        onQuickWait: widget.onQuickWait,
                        onEditTask: widget.onEditTask,
                        onDisableTask: _disableTask,
                        onDismissed: _markTaskHidden,
                        dragEnabled: widget.controller.canUseDesktopDragCopy,
                        swipeEnabled: !_isSwipeDisabled(task),
                        activeDragPayload: dragPayload,
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  /// Builds the local overview search field above the task list.
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: I18n.taskSearchHint.tr,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => setState(() {
        _searchQuery = value.trim().toLowerCase();
      }),
    );
  }

  /// Returns the placeholder message for the current filtered view.
  String get _emptyMessage {
    return _searchQuery.isEmpty ? I18n.homeNoTask.tr : I18n.taskNotFound.tr;
  }

  /// Collects the current overview task snapshot from the active script model.
  List<TaskStatusViewData> _collectTasks(ScriptModel model) {
    final tasks = <TaskStatusViewData>[];
    final runningName = model.runningTask.value.taskName.value.trim();
    if (runningName.isNotEmpty) {
      tasks.add(TaskStatusViewData(
        rowId: 'running::$runningName',
        name: runningName,
        type: TaskStatusType.running,
      ));
    }
    for (final entry in model.pendingTaskList.indexed) {
      final name = entry.$2.taskName.value.trim();
      if (name.isEmpty) {
        continue;
      }
      final timeText = entry.$2.nextRun.value.trim();
      tasks.add(TaskStatusViewData(
        rowId: 'pending::${entry.$1}::$name::$timeText',
        name: name,
        type: TaskStatusType.pending,
        timeText: timeText,
      ));
    }
    for (final entry in model.waitingTaskList.indexed) {
      final name = entry.$2.taskName.value.trim();
      if (name.isEmpty) {
        continue;
      }
      final timeText = entry.$2.nextRun.value.trim();
      tasks.add(TaskStatusViewData(
        rowId: 'waiting::${entry.$1}::$name::$timeText',
        name: name,
        type: TaskStatusType.waiting,
        timeText: timeText,
      ));
    }
    return tasks;
  }

  /// Returns whether one overview task matches the local search query.
  bool _matchesTaskQuery(TaskStatusViewData task) {
    if (_searchQuery.isEmpty) {
      return true;
    }
    final localized = task.name.tr.toLowerCase();
    final original = task.name.toLowerCase();
    return localized.contains(_searchQuery) || original.contains(_searchQuery);
  }

  /// Requests disabling one overview task across the current linker scope.
  Future<bool> _disableTask(String taskName) {
    return widget.controller.toggleTaskEnabled(
      scriptName: widget.scriptModel.name,
      taskName: taskName,
      enable: false,
    );
  }

  /// Returns whether the overview row must reject left-swipe interaction.
  bool _isSwipeDisabled(TaskStatusViewData task) {
    return widget.scriptModel.state.value == ScriptState.running &&
        task.type == TaskStatusType.running;
  }

  /// Records one task that already finished its left-slide removal animation.
  void _markTaskHidden(String rowId) {
    setState(() {
      _hiddenTaskIds.add(rowId);
    });
  }

  /// Clears local search and hidden-row state when the active config changes.
  void _clearSearchState() {
    _hiddenTaskIds.clear();
    _searchController.clear();
    _searchQuery = '';
  }

  /// Releases optimistic hidden rows once the backend snapshot no longer emits them.
  void _pruneHiddenTaskIds(List<TaskStatusViewData> tasks) {
    final activeIds = tasks.map((task) => task.rowId).toSet();
    final staleIds = _hiddenTaskIds
        .where((rowId) => !activeIds.contains(rowId))
        .toList();
    if (staleIds.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || staleIds.isEmpty) {
        return;
      }
      setState(() {
        _hiddenTaskIds.removeAll(staleIds);
      });
    });
  }
}
