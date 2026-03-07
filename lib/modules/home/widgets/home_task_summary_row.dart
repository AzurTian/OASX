part of 'home_task_summary.dart';

class _TaskLine extends StatelessWidget {
  const _TaskLine({
    required this.task,
    required this.scriptState,
    this.onSetTaskArgument,
    this.onOpenTaskSettings,
  });

  static const _rowHeight = 50.0;
  static const _buttonVerticalGap = 4.0;

  final HomeTaskData task;
  final ScriptState scriptState;
  final HomeTaskArgumentSetter? onSetTaskArgument;
  final void Function(String scriptName, String taskName)? onOpenTaskSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelMedium = Theme.of(context).textTheme.labelMedium;
    final rowBackground = switch (task.type) {
      HomeTaskType.running =>
        colorScheme.tertiaryContainer.withValues(alpha: 0.24),
      HomeTaskType.pending =>
        colorScheme.secondaryContainer.withValues(alpha: 0.2),
      HomeTaskType.waiting => colorScheme.surfaceContainerHigh,
    };
    final rowBorder = switch (task.type) {
      HomeTaskType.running => Colors.green.withValues(alpha: 0.28),
      HomeTaskType.pending => Colors.orange.withValues(alpha: 0.3),
      HomeTaskType.waiting => colorScheme.outlineVariant.withValues(alpha: 0.7),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: rowBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rowBorder, width: 1),
      ),
      child: SizedBox(
        height: _rowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _rowHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Align(
                    alignment: Alignment.center,
                    child: _TaskTypeIndicator(
                      type: task.type,
                      scriptState: scriptState,
                      size: constraints.maxHeight - 15,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    task.taskName.tr,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.type != HomeTaskType.running)
                    DateTimePicker(
                      value: task.nextRun,
                      hoverStyle: labelMedium,
                      notHoverStyle: labelMedium,
                      onChange: (nv) async {
                        final ret = onSetTaskArgument == null
                            ? await Get.find<ArgsController>()
                                .updateScriptTaskNextRun(
                                    task.scriptName, task.taskName, nv)
                            : await onSetTaskArgument!(
                                task.scriptName,
                                task.taskName,
                                ArgsController.schedulerGroup,
                                ArgsController.nextRunArg,
                                'next_run',
                                nv,
                              );
                        if (ret) {
                          Get.snackbar(
                            I18n.settingSaved.tr,
                            nv,
                            duration: const Duration(seconds: 1),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 60,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _openTaskSettings(context),
                child: Center(
                  child: Text(
                    I18n.setting.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ).paddingSymmetric(vertical: _buttonVerticalGap),
          ],
        ).paddingSymmetric(horizontal: 5),
      ),
    );
  }

  void _openTaskSettings(BuildContext context) {
    if (onOpenTaskSettings != null) {
      onOpenTaskSettings!(task.scriptName, task.taskName);
      return;
    }
    HomeTaskSettingsDialog.show(
      scriptName: task.scriptName,
      taskName: task.taskName,
    );
  }
}

class _TaskTypeIndicator extends StatelessWidget {
  const _TaskTypeIndicator({
    required this.type,
    required this.scriptState,
    required this.size,
  });

  final HomeTaskType type;
  final ScriptState scriptState;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      HomeTaskType.running => switch (scriptState) {
          ScriptState.running => Icon(
              Icons.bolt_rounded,
              color: Colors.green,
              size: size,
            ),
          ScriptState.warning => Icon(
              Icons.error_rounded,
              color: Colors.orange,
              size: size,
            ),
          ScriptState.inactive => Icon(
              Icons.bolt_outlined,
              color: Colors.grey,
              size: size,
            ),
          ScriptState.updating => Icon(
              Icons.bolt_outlined,
              color: Colors.blueGrey,
              size: size,
            ),
        },
      HomeTaskType.pending => Icon(
          Icons.layers_rounded,
          color: Colors.orange,
          size: size,
        ),
      HomeTaskType.waiting => Icon(
          Icons.schedule_rounded,
          color: Colors.blueGrey,
          size: size,
        ),
    };
  }
}
