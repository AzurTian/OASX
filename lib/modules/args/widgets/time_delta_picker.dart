// ignore_for_file: must_be_immutable
part of args;

class TimeDeltaPicker extends DateTimePickerBase {
  TimeDeltaPicker({super.key, required super.value, required super.onChange});

  @override
  State<StatefulWidget> createState() => TimeDeltaPickerState();
}

class TimeDeltaPickerState extends DateTimePickerBaseState {
  @override
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      data: dateTimeDelta,
      selectData: prePrecess(value),
      onConfirm: onConfirm,
      suffix: [I18n.day.tr, I18n.hour.tr, I18n.minute.tr, I18n.seconds.tr],
    );
  }

  dynamic onConfirm(List<dynamic> p, List<int> position) {
    final day = dateTimeDelta[0][position[0]];
    final hour = dateTimeDelta[1][position[1]];
    final minute = dateTimeDelta[2][position[2]];
    final seconds = dateTimeDelta[3][position[3]];
    widget.onChange('$day $hour:$minute:$seconds');
  }

  List prePrecess(dynamic value) {
    List result = [0, 0, 0, 0];
    if (value is String) {
      result = value.split(RegExp(r'\D+'));
    }
    if (result is double) {
      final duration = Duration(seconds: value.toInt());
      final day = duration.inDays.toString();
      final hour = duration.inHours.toString();
      final minute = duration.inMinutes.toString();
      final seconds = duration.inSeconds.toString();
      result = [day, hour, minute, seconds];
    }
    return result;
  }
}
