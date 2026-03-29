// ignore_for_file: invalid_use_of_protected_member
part of args;

extension _ArgumentViewActions on _ArgumentViewState {
  ArgsController get _argsController => Get.find<ArgsController>();

  bool get _isDraftMode => _argsController.isDraftMode.value;

  void onCheckboxChanged(bool? value) {
    _applyValue(value ?? false, 'boolean', useSetState: true);
  }

  void onStringChanged(String? value) {
    _applyValue(value ?? '', 'string');
  }

  void onNumberChanged(String? value) {
    _applyValue(value ?? '', 'number');
  }

  void onIntegerChanged(String? value) {
    _applyValue(value ?? '', 'integer');
  }

  void onEnumChanged(String? value) {
    _applyValue(value ?? '', 'enum', useSetState: true);
  }

  void onDateTimeChanged(String? value) {
    _applyValue(value ?? '', 'date_time', useSetState: true);
  }

  void onTimeDeltaChanged(String? value) {
    _applyValue(value ?? '', 'time_delta', useSetState: true);
  }

  void onTimeChanged(String? value) {
    _applyValue(value ?? '', 'time', useSetState: true);
  }

  void _applyValue(
    dynamic value,
    String type, {
    bool useSetState = false,
  }) {
    if (_isProtectedImmediateScheduleField) {
      return;
    }
    if (_isDraftMode) {
      if (useSetState) {
        setState(() {
          model.value = value;
        });
      } else {
        model.value = value;
      }
      _argsController.stageArgumentChange(
        widget.getGroupName(),
        model.title,
        value,
        type,
      );
      return;
    }
    if (useSetState) {
      setState(() {
        model.value = value;
      });
    } else {
      model.value = value;
    }
    widget.setArgument(
      widget.scriptName,
      widget.taskName,
      widget.getGroupName(),
      model.title,
      type,
      value,
    );
    showSnakbar(value);
  }

  void showSnakbar(dynamic value) {
    Get.snackbar(
      I18n.settingSaved.tr,
      '$value',
      duration: const Duration(seconds: 1),
    );
  }
}
