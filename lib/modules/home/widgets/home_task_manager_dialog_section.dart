part of 'home_task_manager_dialog.dart';

class _TaskMenuSection extends StatelessWidget {
  const _TaskMenuSection({
    required this.section,
    required this.scriptName,
    required this.forceExpanded,
    this.setArgumentOverride,
  });

  final _TaskSection section;
  final String scriptName;
  final bool forceExpanded;
  final void Function(String? config, String? task, String group,
      String argument, String type, dynamic value)? setArgumentOverride;

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
                style: theme.textTheme.titleMedium?.copyWith(
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
          setArgumentOverride: setArgumentOverride,
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
          Text(I18n.taskMenuLoadFailed.tr),
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
