import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';

/// Stream connection states used by the statistics panel.
enum ScriptStatisticsConnectionState {
  idle,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Chart metrics supported by the statistics view.
enum ScriptStatisticsChartMetric {
  totalDuration,
  runCount,
  battleCount,
  battleAvgDuration,
  avgRunDuration,
}

/// Sort fields supported by the statistics chart.
enum ScriptStatisticsChartSortField {
  data,
  time,
}

/// Available date list returned by `/stats/{config_name}/dates`.
class ScriptStatisticsDateList {
  /// Creates a date list model.
  ScriptStatisticsDateList({
    required this.scriptName,
    required this.dates,
  });

  /// Builds the model from server JSON.
  factory ScriptStatisticsDateList.fromJson(Map<String, dynamic> json) {
    final rawDates = json['dates'];
    final dates = rawDates is List
        ? rawDates.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList()
        : <String>[];
    return ScriptStatisticsDateList(
      scriptName: _readString(json['script_name']),
      dates: dates,
    );
  }

  /// Script/config name.
  final String scriptName;

  /// Selectable dates ordered by backend preference.
  final List<String> dates;
}

/// Battle summary nested under task and run payloads.
class ScriptStatisticsBattleSummary {
  /// Creates a battle summary.
  ScriptStatisticsBattleSummary({
    required this.count,
    required this.avgDurationSeconds,
  });

  /// Builds the summary from server JSON.
  factory ScriptStatisticsBattleSummary.fromJson(Map<String, dynamic> json) {
    return ScriptStatisticsBattleSummary(
      count: _readInt(json['count']),
      avgDurationSeconds: _readDouble(json['avg_duration_seconds']),
    );
  }

  /// Battle count.
  final int count;

  /// Average battle duration in seconds.
  final double avgDurationSeconds;
}

/// One run interval belonging to a task on one selected day.
class ScriptTaskRunRecord {
  /// Creates a run interval from parsed values.
  ScriptTaskRunRecord({
    required this.startTimeText,
    required this.endTimeText,
    required this.durationSeconds,
    required this.battle,
    required DateTime? startTime,
    required DateTime? endTime,
  })  : _startTime = startTime,
        _endTime = endTime;

  /// Builds a run interval from server JSON.
  factory ScriptTaskRunRecord.fromJson(Map<String, dynamic> json) {
    final battleJson = json['battle'];
    final startTimeText = _readString(json['start_time']);
    final endTimeText = _readString(json['end_time']);
    return ScriptTaskRunRecord(
      startTimeText: startTimeText,
      endTimeText: endTimeText,
      durationSeconds: _readDouble(json['duration_seconds']),
      battle: battleJson is Map
          ? ScriptStatisticsBattleSummary.fromJson(
              Map<String, dynamic>.from(battleJson),
            )
          : null,
      startTime: _tryParseDateTime(startTimeText),
      endTime: _tryParseDateTime(endTimeText),
    );
  }

  /// Raw start time text.
  final String startTimeText;

  /// Raw end time text.
  final String endTimeText;

  /// Run duration in seconds.
  final double durationSeconds;

  /// Optional battle summary for this run.
  final ScriptStatisticsBattleSummary? battle;

  /// Cached parsed start time.
  final DateTime? _startTime;

  /// Cached parsed end time.
  final DateTime? _endTime;

  /// Parsed start time for timeline positioning.
  DateTime? get startTime => _startTime;

  /// Parsed end time for timeline positioning.
  DateTime? get endTime => _endTime;

  /// Battle count exposed for chart and detail widgets.
  int get battleCount => battle?.count ?? 0;

  /// Average battle duration exposed for chart and detail widgets.
  double get battleAvgDurationSeconds => battle?.avgDurationSeconds ?? 0;

  /// Stable key used to restore a selected run after updates.
  String get selectionKey {
    return '$startTimeText|$endTimeText|$durationSeconds|$battleCount';
  }

  /// Whether the run contains a valid start and end time.
  bool get hasTimeRange => startTime != null && endTime != null;

  /// Metric value used by the interaction summary.
  double metricValueFor(ScriptStatisticsChartMetric metric) {
    return switch (metric) {
      ScriptStatisticsChartMetric.totalDuration => durationSeconds,
      ScriptStatisticsChartMetric.runCount => 1,
      ScriptStatisticsChartMetric.battleCount => battleCount.toDouble(),
      ScriptStatisticsChartMetric.battleAvgDuration => battleAvgDurationSeconds,
      ScriptStatisticsChartMetric.avgRunDuration => durationSeconds,
    };
  }
}

/// Aggregated task statistics for one selected day.
class ScriptTaskStatistics {
  /// Creates a task aggregate.
  ScriptTaskStatistics({
    required this.runCount,
    required this.totalDurationSeconds,
    required this.battle,
    required this.runs,
    required this.latestRunStartTime,
  });

  /// Builds task aggregates from server JSON.
  factory ScriptTaskStatistics.fromJson(Map<String, dynamic> json) {
    final battleJson = json['battle'];
    final runsJson = json['runs'];
    final runs = runsJson is List
        ? runsJson
            .whereType<Map>()
            .map(
              (item) => ScriptTaskRunRecord.fromJson(
                item.cast<String, dynamic>(),
              ),
            )
            .toList()
        : <ScriptTaskRunRecord>[];
    runs.sort((left, right) {
      final leftTime = left.startTime;
      final rightTime = right.startTime;
      if (leftTime == null && rightTime == null) {
        return 0;
      }
      if (leftTime == null) {
        return 1;
      }
      if (rightTime == null) {
        return -1;
      }
      return leftTime.compareTo(rightTime);
    });
    return ScriptTaskStatistics(
      runCount: _readInt(json['run_count']),
      totalDurationSeconds: _readDouble(json['total_duration_seconds']),
      battle: battleJson is Map
          ? ScriptStatisticsBattleSummary.fromJson(
              Map<String, dynamic>.from(battleJson),
            )
          : null,
      runs: runs,
      latestRunStartTime: _readLatestRunStartTime(runs),
    );
  }

  /// How many times the task ran on that day.
  final int runCount;

  /// Total task runtime in seconds.
  final double totalDurationSeconds;

  /// Optional task-level battle summary.
  final ScriptStatisticsBattleSummary? battle;

  /// Optional run-level details.
  final List<ScriptTaskRunRecord> runs;

  /// Cached latest run time used by time-based sorting.
  final DateTime? latestRunStartTime;

  /// Battle count exposed for chart filtering.
  int get battleCount => battle?.count ?? 0;

  /// Average battle duration exposed for chart filtering.
  double get battleAvgDurationSeconds => battle?.avgDurationSeconds ?? 0;

  /// Average task runtime derived from total duration and run count.
  double get avgRunDurationSeconds {
    if (runCount <= 0) {
      return 0;
    }
    return totalDurationSeconds / runCount;
  }

  /// Metric value used by the chart.
  double metricValueFor(ScriptStatisticsChartMetric metric) {
    return switch (metric) {
      ScriptStatisticsChartMetric.totalDuration => totalDurationSeconds,
      ScriptStatisticsChartMetric.runCount => runCount.toDouble(),
      ScriptStatisticsChartMetric.battleCount => battleCount.toDouble(),
      ScriptStatisticsChartMetric.battleAvgDuration => battleAvgDurationSeconds,
      ScriptStatisticsChartMetric.avgRunDuration => avgRunDurationSeconds,
    };
  }

}

/// Statistics for one selected day.
class ScriptStatisticsDay {
  /// Creates a selected-day statistics document.
  ScriptStatisticsDay({
    required this.scriptName,
    required this.dateKey,
    required this.totalRuntimeSeconds,
    required this.totalTaskRunCount,
    required this.totalBattleCount,
    required this.tasks,
  });

  /// Builds a selected-day snapshot from server JSON.
  factory ScriptStatisticsDay.fromSnapshotJson(
    Map<String, dynamic> json, {
    required String dateKey,
  }) {
    return ScriptStatisticsDay(
      scriptName: _readString(json['script_name']),
      dateKey: dateKey,
      totalRuntimeSeconds: _readDouble(json['total_runtime_seconds']),
      totalTaskRunCount: _readInt(json['total_task_run_count']),
      totalBattleCount: _readInt(json['total_battle_count']),
      tasks: _readTasks(json['tasks']),
    );
  }

  /// Script/config name.
  final String scriptName;

  /// Selected date key using yyyy-MM-dd.
  final String dateKey;

  /// Total script runtime for the selected day.
  final double totalRuntimeSeconds;

  /// Total task run count for the selected day.
  final int totalTaskRunCount;

  /// Total battle count for the selected day.
  final int totalBattleCount;

  /// Task aggregates keyed by task name.
  final Map<String, ScriptTaskStatistics> tasks;

  /// Whether the selected date is today.
  bool get isToday => isStatisticsDateToday(dateKey);

  /// Total distinct task count shown in the summary.
  int get taskCount => tasks.length;

  /// Flattened run entries with their task names.
  List<MapEntry<String, ScriptTaskRunRecord>> get runEntries {
    final entries = <MapEntry<String, ScriptTaskRunRecord>>[];
    for (final entry in tasks.entries) {
      for (final run in entry.value.runs) {
        if (run.hasTimeRange) {
          entries.add(MapEntry(entry.key, run));
        }
      }
    }
    entries.sort((left, right) {
      final leftStart = left.value.startTime;
      final rightStart = right.value.startTime;
      if (leftStart == null && rightStart == null) {
        return 0;
      }
      if (leftStart == null) {
        return 1;
      }
      if (rightStart == null) {
        return -1;
      }
      return leftStart.compareTo(rightStart);
    });
    return entries;
  }

  /// Applies one incremental update to the current selected day.
  ScriptStatisticsDay applyUpdate(ScriptStatisticsUpdate update) {
    final nextTasks = Map<String, ScriptTaskStatistics>.from(tasks);
    for (final entry in update.changedTasks.entries) {
      nextTasks[entry.key] = entry.value;
    }
    for (final taskName in update.removedTasks) {
      nextTasks.remove(taskName);
    }
    return ScriptStatisticsDay(
      scriptName: update.scriptName.isEmpty ? scriptName : update.scriptName,
      dateKey: dateKey,
      totalRuntimeSeconds: update.totalRuntimeSeconds,
      totalTaskRunCount: update.totalTaskRunCount,
      totalBattleCount: update.totalBattleCount,
      tasks: nextTasks,
    );
  }
}

/// Single update payload carried by today SSE events.
class ScriptStatisticsUpdate {
  /// Creates a day update wrapper.
  ScriptStatisticsUpdate({
    required this.scriptName,
    required this.totalRuntimeSeconds,
    required this.totalTaskRunCount,
    required this.totalBattleCount,
    required this.changedTasks,
    required this.removedTasks,
  });

  /// Builds a day update from server JSON.
  factory ScriptStatisticsUpdate.fromJson(Map<String, dynamic> json) {
    final removedTasks = json['removed_tasks'];
    return ScriptStatisticsUpdate(
      scriptName: _readString(json['script_name']),
      totalRuntimeSeconds: _readDouble(json['total_runtime_seconds']),
      totalTaskRunCount: _readInt(json['total_task_run_count']),
      totalBattleCount: _readInt(json['total_battle_count']),
      changedTasks: _readTasks(json['changed_tasks']),
      removedTasks: removedTasks is List
          ? removedTasks.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList()
          : <String>[],
    );
  }

  /// Script/config name.
  final String scriptName;

  /// Updated runtime total.
  final double totalRuntimeSeconds;

  /// Updated task run total.
  final int totalTaskRunCount;

  /// Updated battle total.
  final int totalBattleCount;

  /// Tasks replaced by the update event.
  final Map<String, ScriptTaskStatistics> changedTasks;

  /// Tasks removed by the update event.
  final List<String> removedTasks;
}

/// Parses timestamp text used by the statistics payload.
DateTime? tryParseStatisticsDateTime(String value) {
  return _tryParseDateTime(value);
}

/// Parses one selected-day snapshot in a background isolate.
Future<ScriptStatisticsDay> parseScriptStatisticsDayAsync(
  Map<String, dynamic> json, {
  required String dateKey,
}) {
  return Isolate.run(
    () => ScriptStatisticsDay.fromSnapshotJson(
      Map<String, dynamic>.from(json),
      dateKey: dateKey,
    ),
  );
}

/// Parses one snapshot SSE payload in a background isolate.
Future<ScriptStatisticsDay> parseScriptStatisticsSnapshotPayloadAsync(
  String payloadText, {
  required String dateKey,
}) {
  return Isolate.run(() {
    return ScriptStatisticsDay.fromSnapshotJson(
      _decodeStatisticsPayload(payloadText),
      dateKey: dateKey,
    );
  });
}

/// Parses one update SSE payload in a background isolate.
Future<ScriptStatisticsUpdate> parseScriptStatisticsUpdatePayloadAsync(
  String payloadText,
) {
  return Isolate.run(() {
    return ScriptStatisticsUpdate.fromJson(
      _decodeStatisticsPayload(payloadText),
    );
  });
}

/// Returns whether the metric should be formatted as a duration.
bool statisticsMetricUsesDuration(ScriptStatisticsChartMetric metric) {
  return switch (metric) {
    ScriptStatisticsChartMetric.totalDuration ||
    ScriptStatisticsChartMetric.battleAvgDuration ||
    ScriptStatisticsChartMetric.avgRunDuration => true,
    ScriptStatisticsChartMetric.runCount ||
    ScriptStatisticsChartMetric.battleCount => false,
  };
}

/// Returns whether zero battle rows should be hidden for the metric.
bool statisticsMetricUsesBattleFilter(ScriptStatisticsChartMetric metric) {
  return switch (metric) {
    ScriptStatisticsChartMetric.battleCount ||
    ScriptStatisticsChartMetric.battleAvgDuration => true,
    ScriptStatisticsChartMetric.totalDuration ||
    ScriptStatisticsChartMetric.runCount ||
    ScriptStatisticsChartMetric.avgRunDuration => false,
  };
}

/// Returns whether the provided date key matches the current local day.
bool isStatisticsDateToday(String dateKey) {
  final selectedDate = DateTime.tryParse(dateKey);
  if (selectedDate == null) {
    return false;
  }
  final now = DateTime.now();
  return selectedDate.year == now.year &&
      selectedDate.month == now.month &&
      selectedDate.day == now.day;
}

/// Returns a stable color for a task name.
Color statisticsTaskColor(String taskName) {
  const palette = <Color>[
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
  ];
  return palette[taskName.hashCode.abs() % palette.length];
}

/// Reads a task map from the payload.
Map<String, ScriptTaskStatistics> _readTasks(dynamic value) {
  final tasks = <String, ScriptTaskStatistics>{};
  if (value is! Map) {
    return tasks;
  }
  for (final entry in value.entries) {
    if (entry.value is Map) {
      tasks[entry.key.toString()] = ScriptTaskStatistics.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }
  }
  return tasks;
}

/// Reads a string value safely.
String _readString(dynamic value) => value?.toString().trim() ?? '';

/// Reads an int value safely.
int _readInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_readString(value)) ?? 0;
}

/// Reads a double value safely.
double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(_readString(value)) ?? 0;
}

/// Parses the timestamp format used by the backend payload.
DateTime? _tryParseDateTime(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }
  final isoText = normalized.contains('T')
      ? normalized
      : normalized.replaceFirst(' ', 'T');
  return DateTime.tryParse(isoText);
}

/// Decodes one raw statistics payload string into a normalized JSON map.
Map<String, dynamic> _decodeStatisticsPayload(String payloadText) {
  final payload = jsonDecode(payloadText);
  if (payload is! Map) {
    throw const FormatException('Invalid statistics payload');
  }
  return Map<String, dynamic>.from(
    payload.map((key, value) => MapEntry(key.toString(), value)),
  );
}

/// Returns the latest parsed run start time from one task run list.
DateTime? _readLatestRunStartTime(List<ScriptTaskRunRecord> runs) {
  for (final run in runs.reversed) {
    final startTime = run.startTime;
    if (startTime != null) {
      return startTime;
    }
  }
  return null;
}
