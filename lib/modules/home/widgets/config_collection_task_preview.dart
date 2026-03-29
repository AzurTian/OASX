import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigCollectionTaskPreview extends StatelessWidget {
  const ConfigCollectionTaskPreview({
    super.key,
    required this.script,
  });

  final ScriptModel script;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preview = _firstTaskPreview(script);
      if (preview == null) {
        return Text(
          I18n.homeNoTask.tr,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            preview.icon,
            size: 14,
            color: preview.color,
          ),
          const SizedBox(width: 4),
          Text(
            preview.displayName,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      );
    });
  }

  _TaskPreviewData? _firstTaskPreview(ScriptModel model) {
    final runningTask = model.runningTask.value;
    final runningName = runningTask.taskName.value.trim();
    if (runningName.isNotEmpty) {
      return _TaskPreviewData(
        type: _PreviewTaskType.running,
        name: runningName,
      );
    }
    for (final task in model.pendingTaskList) {
      final taskName = task.taskName.value.trim();
      if (taskName.isEmpty) {
        continue;
      }
      return _TaskPreviewData(
        type: _PreviewTaskType.pending,
        name: taskName,
      );
    }
    for (final task in model.waitingTaskList) {
      final taskName = task.taskName.value.trim();
      if (taskName.isEmpty) {
        continue;
      }
      return _TaskPreviewData(
        type: _PreviewTaskType.waiting,
        name: taskName,
        timeText: task.nextRun.value.trim(),
      );
    }
    return null;
  }
}

enum _PreviewTaskType {
  running,
  pending,
  waiting,
}

class _TaskPreviewData {
  const _TaskPreviewData({
    required this.type,
    required this.name,
    this.timeText = '',
  });

  final _PreviewTaskType type;
  final String name;
  final String timeText;

  String get displayName {
    final localizedName = name.tr;
    if (timeText.isEmpty || type != _PreviewTaskType.waiting) {
      return localizedName;
    }
    return '$localizedName ${_timeOfDayText(timeText)}';
  }

  String _timeOfDayText(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return normalized;
    }
    final parts = normalized.split(' ');
    return parts.isEmpty ? normalized : parts.last;
  }

  IconData get icon {
    return switch (type) {
      _PreviewTaskType.running => Icons.bolt_rounded,
      _PreviewTaskType.pending => Icons.layers_rounded,
      _PreviewTaskType.waiting => Icons.schedule_rounded,
    };
  }

  Color get color {
    return switch (type) {
      _PreviewTaskType.running => Colors.green,
      _PreviewTaskType.pending => Colors.orange,
      _PreviewTaskType.waiting => Colors.blueGrey,
    };
  }
}
