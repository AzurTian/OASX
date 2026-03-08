// ignore_for_file: invalid_use_of_protected_member
part of args;

extension _ArgumentViewActions on _ArgumentViewState {
  void onCheckboxChanged(bool? value) {
    setState(() {
      widget.setArgument(
        widget.scriptName,
        widget.taskName,
        widget.getGroupName(),
        model.title,
        'boolean',
        value,
      );
      model.value = value;
    });
    showSnakbar(value);
  }

  void onStringChanged(String? value) {
    widget.setArgument(
      widget.scriptName,
      widget.taskName,
      widget.getGroupName(),
      model.title,
      'string',
      value,
    );
    showSnakbar(value);
  }

  void onNumberChanged(String? value) {
    widget.setArgument(
      widget.scriptName,
      widget.taskName,
      widget.getGroupName(),
      model.title,
      'number',
      value,
    );
    showSnakbar(value);
  }

  void onIntegerChanged(String? value) {
    widget.setArgument(
      widget.scriptName,
      widget.taskName,
      widget.getGroupName(),
      model.title,
      'integer',
      value,
    );
    showSnakbar(value);
  }

  void onEnumChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(
        widget.scriptName,
        widget.taskName,
        widget.getGroupName(),
        model.title,
        'enum',
        value,
      );
    });
    showSnakbar(value);
  }

  void onDateTimeChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(
        widget.scriptName,
        widget.taskName,
        widget.getGroupName(),
        model.title,
        'date_time',
        value,
      );
    });
    showSnakbar(value);
  }

  void onTimeDeltaChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(
        widget.scriptName,
        widget.taskName,
        widget.getGroupName(),
        model.title,
        'time_delta',
        value,
      );
    });
    showSnakbar(value);
  }

  void onTimeChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(
        widget.scriptName,
        widget.taskName,
        widget.getGroupName(),
        model.title,
        'time',
        value,
      );
    });
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

