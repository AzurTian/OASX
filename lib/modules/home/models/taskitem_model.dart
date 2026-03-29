import 'package:get/get.dart';

/// Model describing a scheduled task entry for a script.
class TaskItemModel {
  /// Script name owning this task.
  final String scriptName;

  /// Task name in displayable form.
  final taskName = ''.obs;

  /// Next scheduled run timestamp.
  final nextRun = ''.obs;

  /// Optional group name for grouping in the UI.
  String? groupName;

  /// Creates a task item with the provided values.
  TaskItemModel(this.scriptName, taskName, nextRun, {this.groupName = ''}) {
    this.taskName.value = taskName;
    this.nextRun.value = nextRun;
  }

  /// Returns a placeholder empty task entry.
  static TaskItemModel empty() {
    return TaskItemModel('', '', '');
  }

  /// Returns true when both task name and next run are unset.
  bool isAllEmpty() {
    return taskName.isEmpty && nextRun.isEmpty;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItemModel &&
          runtimeType == other.runtimeType &&
          scriptName == other.scriptName &&
          taskName == other.taskName &&
          nextRun == other.nextRun;

  @override
  int get hashCode => Object.hash(scriptName, taskName, nextRun);
}
