part of 'home_task_summary.dart';

typedef HomeTaskArgumentSetter = Future<bool> Function(
  String scriptName,
  String taskName,
  String group,
  String argument,
  String type,
  dynamic value,
);

enum HomeTaskType {
  running,
  pending,
  waiting,
}

class HomeTaskData {
  const HomeTaskData({
    required this.type,
    required this.scriptName,
    required this.taskName,
    this.nextRun = '',
  });

  final HomeTaskType type;
  final String scriptName;
  final String taskName;
  final String nextRun;
}
