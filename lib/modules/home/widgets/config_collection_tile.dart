import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/split_scroll_row.dart';
import 'package:oasx/modules/home/widgets/config_collection_task_preview.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigCollectionTile extends StatelessWidget {
  const ConfigCollectionTile({
    super.key,
    required this.controller,
    required this.script,
    required this.state,
    required this.onTap,
    required this.onTogglePower,
    required this.onRename,
    required this.onDelete,
  });

  static const _actionExtent = 96.0;
  final HomeDashboardController controller;
  final ScriptModel script;
  final HomeScriptStateFilter state;
  final VoidCallback onTap;
  final VoidCallback onTogglePower;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isActive = controller.activeScriptName.value == script.name;
      final showLinkCheckbox = controller.isLinkModeEnabled.value;
      final isLinked = controller.isScriptLinked(script.name);
      final rowColor = isActive
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.24)
          : theme.cardColor;
      return Material(
        color: rowColor,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                if (showLinkCheckbox) ...[
                  Checkbox(
                    value: isLinked,
                    onChanged: (value) =>
                        controller.setScriptLinked(script.name, value ?? false),
                  ),
                  const SizedBox(width: 4),
                ],
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accentColor(context, state),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SplitScrollRow(
                    trailingExtent: _actionExtent,
                    trailingBackgroundColor: rowColor,
                    trailing: _ScriptActionBar(
                      onTogglePower: onTogglePower,
                      onRename: onRename,
                      onDelete: onDelete,
                    ),
                    leading: _ScriptMeta(script: script),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Color _accentColor(BuildContext context, HomeScriptStateFilter value) {
    final scheme = Theme.of(context).colorScheme;
    return switch (value) {
      HomeScriptStateFilter.running => Colors.green.shade600,
      HomeScriptStateFilter.stopped => scheme.outline,
      HomeScriptStateFilter.abnormal => Colors.orange.shade700,
      HomeScriptStateFilter.offline => Colors.orange.shade700,
      HomeScriptStateFilter.all => scheme.outline,
    };
  }
}

class _ScriptMeta extends StatelessWidget {
  const _ScriptMeta({
    required this.script,
  });

  final ScriptModel script;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          script.name,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 2),
        ConfigCollectionTaskPreview(script: script),
      ],
    );
  }
}

class _ScriptActionBar extends StatelessWidget {
  const _ScriptActionBar({
    required this.onTogglePower,
    required this.onRename,
    required this.onDelete,
  });

  final VoidCallback onTogglePower;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTogglePower,
          icon: const Icon(Icons.power_settings_new_rounded),
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'rename') {
              onRename();
              return;
            }
            onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'rename', child: Text(I18n.rename.tr)),
            PopupMenuItem(value: 'delete', child: Text(I18n.delete.tr)),
          ],
        ),
      ],
    );
  }
}

