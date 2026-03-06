import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/home/widgets/home_task_settings_dialog.dart';

class HomeTaskManagerDialog extends StatefulWidget {
  const HomeTaskManagerDialog({
    super.key,
    required this.scriptName,
  });

  final String scriptName;

  static Future<void> show({
    required BuildContext context,
    required String scriptName,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => HomeTaskManagerDialog(scriptName: scriptName),
    );
  }

  @override
  State<HomeTaskManagerDialog> createState() => _HomeTaskManagerDialogState();
}

class _HomeTaskManagerDialogState extends State<HomeTaskManagerDialog> {
  late Future<Map<String, List<String>>> _menuFuture;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _menuFuture = ApiClient().getScriptMenu();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxWidth = min(680.0, size.width * 0.86);
    final maxHeight = min(620.0, size.height * 0.8);

    return AlertDialog(
      title: Text('${widget.scriptName} ${I18n.task_manage_title.tr}'),
      content: SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: I18n.task_search_hint.tr,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _keyword = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<Map<String, List<String>>>(
                future: _menuFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _TaskMenuError(
                      error: snapshot.error?.toString() ?? '',
                      onRetry: _reloadMenu,
                    );
                  }
                  final rawMenu = snapshot.data ?? const <String, List<String>>{};
                  final sections = _buildSections(rawMenu, _keyword);
                  final searching = _keyword.trim().isNotEmpty;
                  if (sections.isEmpty) {
                    return Center(
                      child: Text(I18n.task_not_found.tr),
                    );
                  }

                  return ListView.separated(
                    itemCount: sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return _TaskMenuSection(
                        section: section,
                        scriptName: widget.scriptName,
                        forceExpanded: searching,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reloadMenu() {
    setState(() {
      _menuFuture = ApiClient().getScriptMenu();
    });
  }

  List<_TaskSection> _buildSections(
    Map<String, List<String>> menu,
    String keyword,
  ) {
    final normalizedKeyword = keyword.trim().toLowerCase();
    final sections = <_TaskSection>[];

    for (final entry in menu.entries) {
      final groupName = entry.key.trim();
      if (groupName.isEmpty) {
        continue;
      }
      final tasks = <String>[];
      final seenTasks = <String>{};
      for (final rawTask in entry.value) {
        final task = rawTask.trim();
        if (task.isEmpty) {
          continue;
        }
        if (!seenTasks.add(task)) {
          continue;
        }
        if (normalizedKeyword.isNotEmpty) {
          final localized = task.tr.toLowerCase();
          final original = task.toLowerCase();
          final matched = localized.contains(normalizedKeyword) ||
              original.contains(normalizedKeyword);
          if (!matched) {
            continue;
          }
        }
        tasks.add(task);
      }
      if (tasks.isEmpty) {
        continue;
      }
      sections.add(_TaskSection(groupName: groupName, taskNames: tasks));
    }

    return sections;
  }
}

class _TaskMenuSection extends StatelessWidget {
  const _TaskMenuSection({
    required this.section,
    required this.scriptName,
    required this.forceExpanded,
  });

  final _TaskSection section;
  final String scriptName;
  final bool forceExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (forceExpanded) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.groupName.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...section.taskNames.map((taskName) => _buildTaskTile(taskName)),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        key: ValueKey(section.groupName),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        collapsedBackgroundColor: colorScheme.surfaceContainerLowest,
        backgroundColor: colorScheme.surfaceContainerLowest,
        title: Text(
          section.groupName.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Container(
            color: colorScheme.surfaceContainerLow,
            child: Column(
              children: section.taskNames.map(_buildTaskTile).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(String taskName) {
    return ListTile(
      dense: true,
      title: Text(
        taskName.tr,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: OutlinedButton.icon(
        onPressed: () => HomeTaskSettingsDialog.show(
          scriptName: scriptName,
          taskName: taskName,
        ),
        icon: const Icon(Icons.settings_rounded, size: 18),
        label: Text(I18n.setting.tr),
      ),
    );
  }
}

class _TaskMenuError extends StatelessWidget {
  const _TaskMenuError({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(I18n.task_menu_load_failed.tr),
          if (error.isNotEmpty)
            Text(
              error,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(I18n.retry.tr),
          ),
        ],
      ),
    );
  }
}

class _TaskSection {
  const _TaskSection({
    required this.groupName,
    required this.taskNames,
  });

  final String groupName;
  final List<String> taskNames;
}
