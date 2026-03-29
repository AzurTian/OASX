import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/widgets/home_task_settings_dialog.dart';
import 'package:oasx/translation/i18n_content.dart';

part 'home_task_manager_dialog_section.dart';

class HomeTaskManagerDialog extends StatefulWidget {
  const HomeTaskManagerDialog({
    super.key,
    required this.scriptName,
    this.saveArgumentOverride,
  });

  final String scriptName;
  final SaveArgumentCallback? saveArgumentOverride;

  static Future<void> show({
    required BuildContext context,
    required String scriptName,
    SaveArgumentCallback? saveArgumentOverride,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => HomeTaskManagerDialog(
        scriptName: scriptName,
        saveArgumentOverride: saveArgumentOverride,
      ),
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
      title: Text('${widget.scriptName} ${I18n.taskManageTitle.tr}'),
      content: SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: I18n.taskSearchHint.tr,
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
                    return Center(child: Text(I18n.taskNotFound.tr));
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
                        saveArgumentOverride: widget.saveArgumentOverride,
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
        if (task.isEmpty || !seenTasks.add(task)) {
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
      if (tasks.isNotEmpty) {
        sections.add(_TaskSection(groupName: groupName, taskNames: tasks));
      }
    }

    return sections;
  }
}
