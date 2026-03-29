import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/home_dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/split_scroll_row.dart';
import 'package:oasx/modules/home/widgets/task_parameter_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

class TaskCatalogPanel extends StatefulWidget {
  const TaskCatalogPanel({
    super.key,
    required this.controller,
    required this.scriptModel,
    required this.onOpenTask,
    required this.onQuickRun,
    required this.onQuickWait,
  });

  final HomeDashboardController controller;
  final ScriptModel scriptModel;
  final Future<void> Function(String taskName) onOpenTask;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;

  @override
  State<TaskCatalogPanel> createState() => _TaskCatalogPanelState();
}

class _TaskCatalogPanelState extends State<TaskCatalogPanel> {
  late final Future<Map<String, List<String>>> _menuFuture;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedGroups = <String>{};
  final Map<String, bool> _enabledOverrides = <String, bool>{};
  final Set<String> _togglingTasks = <String>{};
  String _searchQuery = '';
  HomeTaskCatalogFilter _filter = HomeTaskCatalogFilter.all;

  @override
  void initState() {
    super.initState();
    _menuFuture = ApiClient().getScriptMenu();
  }

  @override
  void didUpdateWidget(covariant TaskCatalogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptModel.name == widget.scriptModel.name) {
      return;
    }
    _enabledOverrides.clear();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeTask = widget.controller.activeTaskName.value.trim();
      return IndexedStack(
        index: activeTask.isEmpty ? 0 : 1,
        children: [
          _buildTaskList(context),
          TaskParameterPanel(
            controller: widget.controller,
            scriptModel: widget.scriptModel,
            onBack: _handleBackFromParameters,
          ),
        ],
      );
    });
  }

  Widget _buildTaskList(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<Map<String, List<String>>>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('${I18n.error.tr}: ${snapshot.error}'));
              }
              final enabledTaskNames =
                  widget.controller.enabledTaskNamesFor(widget.scriptModel);
              _syncEnabledOverrides(enabledTaskNames);
              final sections = _sections(
                snapshot.data ?? const <String, List<String>>{},
                enabledTaskNames,
              );
              if (sections.isEmpty) {
                return Center(child: Text(I18n.taskNotFound.tr));
              }
              return ListView.separated(
                key: const PageStorageKey<String>('home-task-catalog-list'),
                controller: _scrollController,
                itemCount: sections.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.7),
                  ),
                ),
                itemBuilder: (context, index) => _CatalogSectionCard(
                  section: sections[index],
                  expanded: _expandedGroups.contains(sections[index].groupName),
                  forceExpanded: _searchQuery.isNotEmpty,
                  togglingTasks: _togglingTasks,
                  onToggleExpanded: () =>
                      _handleGroupToggle(sections[index].groupName),
                  onToggleEnabled: (task, value) =>
                      _handleToggleTaskEnabled(task, value),
                  onOpenTask: widget.onOpenTask,
                  onQuickRun: widget.onQuickRun,
                  onQuickWait: widget.onQuickWait,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final searchField = TextField(
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
    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 10),
        PopupMenuButton<HomeTaskCatalogFilter>(
          tooltip: _filterLabel(_filter),
          initialValue: _filter,
          onSelected: (value) => setState(() {
            _filter = value;
          }),
          itemBuilder: (context) => HomeTaskCatalogFilter.values
              .map(
                (value) => PopupMenuItem<HomeTaskCatalogFilter>(
                  value: value,
                  child: Text(_filterLabel(value)),
                ),
              )
              .toList(),
          icon: Icon(
            Icons.filter_list_rounded,
            color: _filter == HomeTaskCatalogFilter.all
                ? null
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  List<_CatalogSectionData> _sections(
    Map<String, List<String>> menu,
    Set<String> enabledTaskNames,
  ) {
    final sections = <_CatalogSectionData>[];
    for (final entry in menu.entries) {
      final tasks = <_CatalogTaskData>[];
      for (final rawTask in entry.value) {
        final taskName = rawTask.trim();
        if (taskName.isEmpty) {
          continue;
        }
        final enabled = _enabledOverrides[taskName] ?? enabledTaskNames.contains(taskName);
        if (!_matchesFilter(taskName, enabled)) {
          continue;
        }
        tasks.add(
          _CatalogTaskData(
            name: taskName,
            groupName: entry.key,
            enabled: enabled,
          ),
        );
      }
      if (tasks.isNotEmpty) {
        sections.add(_CatalogSectionData(groupName: entry.key, tasks: tasks));
      }
    }
    return sections;
  }

  bool _matchesFilter(String taskName, bool enabled) {
    final visible = switch (_filter) {
      HomeTaskCatalogFilter.all => true,
      HomeTaskCatalogFilter.enabled => enabled,
      HomeTaskCatalogFilter.disabled => !enabled,
    };
    if (!visible) {
      return false;
    }
    if (_searchQuery.isEmpty) {
      return true;
    }
    final localized = taskName.tr.toLowerCase();
    final original = taskName.toLowerCase();
    return localized.contains(_searchQuery) || original.contains(_searchQuery);
  }

  String _filterLabel(HomeTaskCatalogFilter value) {
    return switch (value) {
      HomeTaskCatalogFilter.all => I18n.homeTaskFilterAll.tr,
      HomeTaskCatalogFilter.enabled => I18n.homeTaskFilterEnabled.tr,
      HomeTaskCatalogFilter.disabled => I18n.homeTaskFilterDisabled.tr,
    };
  }

  void _handleGroupToggle(String groupName) {
    setState(() {
      if (_expandedGroups.contains(groupName)) {
        _expandedGroups.remove(groupName);
        return;
      }
      _expandedGroups.add(groupName);
    });
  }

  Future<void> _handleBackFromParameters() async {
    await Get.find<ArgsController>().discardDraftChanges();
    widget.controller.clearActiveTask();
  }

  void _syncEnabledOverrides(Set<String> enabledTaskNames) {
    final syncedKeys = _enabledOverrides.entries
        .where((entry) => entry.value == enabledTaskNames.contains(entry.key))
        .map((entry) => entry.key)
        .toList();
    if (syncedKeys.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || syncedKeys.isEmpty) {
        return;
      }
      setState(() {
        for (final key in syncedKeys) {
          _enabledOverrides.remove(key);
        }
      });
    });
  }

  Future<void> _handleToggleTaskEnabled(_CatalogTaskData task, bool enable) async {
    if (_togglingTasks.contains(task.name)) {
      return;
    }
    setState(() {
      _togglingTasks.add(task.name);
    });
    final ret = await widget.controller.quickToggleTaskEnabled(
      scriptName: widget.scriptModel.name,
      taskName: task.name,
      enable: enable,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _togglingTasks.remove(task.name);
      if (!ret) {
        return;
      }
      _enabledOverrides[task.name] = enable;
      task.enabled = enable;
    });
  }
}

class _CatalogSectionTitle extends StatelessWidget {
  const _CatalogSectionTitle({
    required this.section,
  });

  final _CatalogSectionData section;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            section.groupName.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${section.tasks.length}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _CatalogTaskRow extends StatelessWidget {
  const _CatalogTaskRow({
    required this.task,
    required this.loading,
    required this.onToggleEnabled,
    required this.onOpenTask,
    required this.onQuickRun,
    required this.onQuickWait,
  });

  final _CatalogTaskData task;
  final bool loading;
  final ValueChanged<bool> onToggleEnabled;
  final Future<void> Function(String taskName) onOpenTask;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  static const _actionExtent = 132.0;
  static const _minRowHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final rowBackground =
        Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.18);
    final isScriptGroup = task.groupName == I18n.script;
    final supportsEnable = !isScriptGroup || task.name == I18n.restart;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SplitScrollRow(
        scrollKey: PageStorageKey<String>('task-row-scroll-${task.name}'),
        minHeight: _minRowHeight,
        trailingExtent: _actionExtent,
        trailingBackgroundColor: rowBackground,
        trailing: _TaskIconBar(
          task: task,
          onOpenTask: onOpenTask,
          onQuickRun: onQuickRun,
          onQuickWait: onQuickWait,
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (supportsEnable)
              _EnableIcon(
                enabled: task.enabled,
                loading: loading,
                onTap: onToggleEnabled,
              )
            else
              const SizedBox(width: 22, height: 22),
            const SizedBox(width: 10),
            Text(
              task.name.tr,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnableIcon extends StatelessWidget {
  const _EnableIcon({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final ValueChanged<bool> onTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    final icon = enabled ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded;
    final color = enabled ? scheme.onSurface : scheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onTap(!enabled),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _CatalogSectionCard extends StatelessWidget {
  const _CatalogSectionCard({
    required this.section,
    required this.expanded,
    required this.forceExpanded,
    required this.togglingTasks,
    required this.onToggleExpanded,
    required this.onToggleEnabled,
    required this.onOpenTask,
    required this.onQuickRun,
    required this.onQuickWait,
  });

  final _CatalogSectionData section;
  final bool expanded;
  final bool forceExpanded;
  final Set<String> togglingTasks;
  final VoidCallback onToggleExpanded;
  final Future<void> Function(_CatalogTaskData task, bool enable) onToggleEnabled;
  final Future<void> Function(String taskName) onOpenTask;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;

  @override
  Widget build(BuildContext context) {
    final effectiveExpanded = forceExpanded || expanded;
    final scheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardColor;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: effectiveExpanded ? cardColor : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: forceExpanded ? null : onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: _CatalogSectionTitle(section: section)),
                  const SizedBox(width: 10),
                  Icon(
                    effectiveExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (effectiveExpanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (int index = 0; index < section.tasks.length; index++) ...[
                    if (index > 0) const Divider(height: 1),
                    _CatalogTaskRow(
                      task: section.tasks[index],
                      loading: togglingTasks.contains(section.tasks[index].name),
                      onToggleEnabled: (value) =>
                          onToggleEnabled(section.tasks[index], value),
                      onOpenTask: onOpenTask,
                      onQuickRun: onQuickRun,
                      onQuickWait: onQuickWait,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskIconBar extends StatelessWidget {
  const _TaskIconBar({
    required this.task,
    required this.onOpenTask,
    required this.onQuickRun,
    required this.onQuickWait,
  });

  final _CatalogTaskData task;
  final Future<void> Function(String taskName) onOpenTask;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;

  @override
  Widget build(BuildContext context) {
    final isScriptGroup = task.groupName == I18n.script;
    final showQuickActions = !isScriptGroup || task.name == I18n.restart;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showQuickActions)
          _IconOnlyButton(
            icon: Icons.flash_on_rounded,
            tooltip: I18n.homeQuickRun.tr,
            onPressed: task.enabled ? () => onQuickRun(task.name) : null,
          ),
        if (showQuickActions)
          _IconOnlyButton(
            icon: Icons.schedule_rounded,
            tooltip: I18n.homeQuickWait.tr,
            onPressed: task.enabled ? () => onQuickWait(task.name) : null,
          ),
        _IconOnlyButton(
          icon: Icons.tune_rounded,
          tooltip: I18n.homeOpenTaskParams.tr,
          onPressed: () => onOpenTask(task.name),
        ),
      ],
    );
  }
}

class _IconOnlyButton extends StatelessWidget {
  const _IconOnlyButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

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

class _CatalogSectionData {
  const _CatalogSectionData({
    required this.groupName,
    required this.tasks,
  });

  final String groupName;
  final List<_CatalogTaskData> tasks;
}

class _CatalogTaskData {
  _CatalogTaskData({
    required this.name,
    required this.groupName,
    required this.enabled,
  });

  final String name;
  final String groupName;
  bool enabled;
}
