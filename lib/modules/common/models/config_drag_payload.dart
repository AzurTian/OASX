/// Identifies which copy flow a config drag session represents.
enum ConfigDragKind {
  /// Copies one task between configs.
  task,

  /// Copies one task group between configs.
  group,

  /// Copies every task inside one catalog group between configs.
  taskCatalogGroup,
}

/// Carries the source metadata for a config-to-config drag copy.
class ConfigDragPayload {
  /// Creates one task-copy payload.
  const ConfigDragPayload.task({
    required this.sourceConfigName,
    required this.taskName,
  })  : kind = ConfigDragKind.task,
        groupName = '',
        taskNames = const <String>[],
        displayLabel = taskName;

  /// Creates one group-copy payload.
  const ConfigDragPayload.group({
    required this.sourceConfigName,
    required this.taskName,
    required this.groupName,
  })  : kind = ConfigDragKind.group,
        taskNames = const <String>[],
        displayLabel = groupName;

  /// Creates one task-catalog-group-copy payload.
  const ConfigDragPayload.taskCatalogGroup({
    required this.sourceConfigName,
    required this.groupName,
    required this.taskNames,
  })  : kind = ConfigDragKind.taskCatalogGroup,
        taskName = '',
        displayLabel = groupName;

  /// Drag payload kind.
  final ConfigDragKind kind;

  /// Config that owns the dragged source.
  final String sourceConfigName;

  /// Task that owns the dragged content.
  final String taskName;

  /// Optional group name for group-copy drags.
  final String groupName;

  /// Optional task list for task-catalog-group copy drags.
  final List<String> taskNames;

  /// Visible label rendered in the floating drag preview.
  final String displayLabel;

  /// Returns whether the payload may be dropped on the destination config.
  bool canDropOn(String destinationConfigName) {
    final normalizedDestination = destinationConfigName.trim();
    return normalizedDestination.isNotEmpty &&
        normalizedDestination != sourceConfigName.trim();
  }

  /// Returns whether the payload matches the task-row drag source.
  bool matchesTask(String sourceConfig, String task) {
    return kind == ConfigDragKind.task &&
        sourceConfigName.trim() == sourceConfig.trim() &&
        taskName.trim() == task.trim();
  }

  /// Returns whether the payload matches the group drag source.
  bool matchesGroup(String sourceConfig, String task, String group) {
    return kind == ConfigDragKind.group &&
        sourceConfigName.trim() == sourceConfig.trim() &&
        taskName.trim() == task.trim() &&
        groupName.trim() == group.trim();
  }

  /// Returns whether the payload matches the task-catalog group drag source.
  bool matchesTaskCatalogGroup(String sourceConfig, String group) {
    return kind == ConfigDragKind.taskCatalogGroup &&
        sourceConfigName.trim() == sourceConfig.trim() &&
        groupName.trim() == group.trim();
  }
}
