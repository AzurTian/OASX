// ignore_for_file: must_be_immutable
part of args;

class TimePicker extends DateTimePickerBase {
  TimePicker({super.key, required super.value, required super.onChange});

  @override
  State<StatefulWidget> createState() => TimePickerState();
}

class TimePickerState extends DateTimePickerBaseState {
  @override
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      data: dateTime,
      selectData: prePrecess(value),
      onConfirm: onConfirm,
      suffix: [I18n.hour.tr, I18n.minute.tr, I18n.seconds.tr],
    );
  }

  dynamic onConfirm(List<dynamic> p, List<int> position) {
    final hour = dateTime[0][position[0]];
    final minute = dateTime[1][position[1]];
    final seconds = dateTime[2][position[2]];
    widget.onChange('$hour:$minute:$seconds');
  }

  List prePrecess(dynamic value) {
    List result = [0, 0, 0, 0];
    if (value is String) {
      result = value.split(RegExp(r'\D+'));
    }
    return result;
  }
}
