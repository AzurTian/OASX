import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/home_dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/translation/i18n_content.dart';

class TaskParameterPanel extends StatefulWidget {
  const TaskParameterPanel({
    super.key,
    required this.controller,
    required this.scriptModel,
    required this.onBack,
  });

  final HomeDashboardController controller;
  final ScriptModel scriptModel;
  final Future<void> Function() onBack;

  @override
  State<TaskParameterPanel> createState() => _TaskParameterPanelState();
}

class _TaskParameterPanelState extends State<TaskParameterPanel> {
  Future<void>? _loadFuture;
  String _loadKey = '';
  String _scriptName = '';
  String _taskName = '';
  bool _lockImmediateScheduling = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureLoad();
  }

  @override
  void didUpdateWidget(covariant TaskParameterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _ensureLoad();
      if (_taskName.isEmpty) {
        return const SizedBox.shrink();
      }
      final future = _loadFuture;
      if (future == null) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  await widget.onBack();
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _taskName.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<void>(
              key: ValueKey(_loadKey),
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('${I18n.error.tr}: ${snapshot.error}'),
                  );
                }
                return Args(
                  key: ValueKey<String>('args-$_loadKey'),
                  scriptName: _scriptName,
                  taskName: _taskName,
                  groupDraggable: false,
                  stagingMode: true,
                  lockImmediateScheduling: _lockImmediateScheduling,
                  onCancel: () async {
                    widget.controller.clearActiveTask();
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }

  void _ensureLoad() {
    final nextTask = widget.controller.activeTaskName.value.trim();
    final nextScript = widget.scriptModel.name.trim();
    final nextScope = widget.controller.linkedScopeScriptsFor(nextScript);
    final runningTaskName = widget.scriptModel.runningTask.value.taskName.value.trim();
    final shouldLockImmediateScheduling =
        nextTask.isNotEmpty && runningTaskName == nextTask;
    final nextKey = '$nextScript/$nextTask';
    final argsController = Get.find<ArgsController>();
    if (_lockImmediateScheduling != shouldLockImmediateScheduling) {
      _lockImmediateScheduling = shouldLockImmediateScheduling;
      if (_lockImmediateScheduling) {
        argsController.discardDraftField(
          ArgsController.schedulerGroup,
          ArgsController.nextRunArg,
        );
      }
    }
    if (nextTask.isEmpty || nextKey == _loadKey) {
      if (nextTask.isEmpty) {
        _loadKey = '';
        _loadFuture = null;
        _scriptName = '';
        _taskName = '';
        _lockImmediateScheduling = false;
        argsController.updateScopeScripts(const []);
      } else {
        argsController.updateScopeScripts(nextScope, config: nextScript);
      }
      return;
    }
    _scriptName = nextScript;
    _taskName = nextTask;
    _loadKey = nextKey;
    _loadFuture = argsController.loadGroups(
      config: _scriptName,
      task: _taskName,
      stagingMode: true,
      scopeScripts: nextScope,
      saveArgumentOverride: (
        config,
        task,
        group,
        argument,
        type,
        value,
      ) {
        return widget.controller.applyLinkedSetArgument(
          config: config,
          task: task,
          group: group,
          argument: argument,
          type: type,
          value: value,
        );
      },
    );
  }
}
