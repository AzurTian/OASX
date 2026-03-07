// ignore_for_file: must_be_immutable

part of args;

final dateYears = <String>['2023', '2024', '2025', '2026'];
final dateMonths = List.generate(
        12, (index) => (index + 1) < 10 ? '0${index + 1}' : '${index + 1}')
    .toList();
final dateDaysInMonth = List.generate(daysInMonth(),
    (index) => (index + 1) < 10 ? '0${index + 1}' : '${index + 1}').toList();
final dateDaysInWeek =
    List.generate(7, (index) => index < 10 ? '0$index' : '$index').toList();
final dateHours =
    List.generate(24, (index) => index < 10 ? '0$index' : '$index').toList();
final dateMinutes =
    List.generate(60, (index) => index < 10 ? '0$index' : '$index').toList();
final dateSeconds =
    List.generate(60, (index) => index < 10 ? '0$index' : '$index').toList();

final dateTimeData = [
  dateYears,
  dateMonths,
  dateDaysInMonth,
  dateHours,
  dateMinutes,
  dateSeconds,
];
final dateTimeDelta = [
  dateDaysInWeek,
  dateHours,
  dateMinutes,
  dateSeconds,
];
final dateTime = [
  dateHours,
  dateMinutes,
  dateSeconds,
];

int daysInMonth() {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  final lastDayOfMonth =
      DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
  return lastDayOfMonth.day;
}

String ensureTimeDeltaString(dynamic value) {
  if (value is String) {
    return value;
  }
  if (value is int || value is double) {
    final duration = Duration(seconds: value.toInt());
    final day0 = duration.inDays;
    final hour0 = duration.inHours.remainder(24);
    final minute0 = duration.inMinutes.remainder(60);
    final second = duration.inSeconds.remainder(60);

    final day = day0 < 10 ? '0$day0' : '$day0';
    final hour = hour0 < 10 ? '0$hour0' : '$hour0';
    final minute = minute0 < 10 ? '0$minute0' : '$minute0';
    final seconds = second < 10 ? '0$second' : '$second';
    return '$day $hour:$minute:$seconds';
  }
  return '00 00:00:00';
}

class DateTimePickerBase extends StatefulWidget {
  DateTimePickerBase({
    super.key,
    required this.value,
    required this.onChange,
    this.hoverStyle,
    this.notHoverStyle,
  });

  String value = '';
  final TextStyle? hoverStyle;
  final TextStyle? notHoverStyle;
  void Function(String value) onChange = (value) {};

  @override
  State<StatefulWidget> createState() => DateTimePickerBaseState();
}

class DateTimePickerBaseState extends State<DateTimePickerBase> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    final hoverStyle = widget.hoverStyle ??
        TextStyle(color: Theme.of(context).primaryColor, fontSize: 16);
    final notHoverStyle = widget.notHoverStyle ?? const TextStyle(fontSize: 16);
    final baseHeight = (hoverStyle.fontSize ?? 16) * 1.2;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: Text(widget.value, style: _isHover ? hoverStyle : notHoverStyle)
          .scale(
            all: _isHover ? 1.1 : 1.0,
            alignment: Alignment.centerLeft,
            animate: true,
          )
          .animate(const Duration(milliseconds: 120), Curves.easeOut)
          .constrained(height: baseHeight)
          .gestures(onTap: () => showPicker(context, widget.value)),
    );
  }

  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      data: dateTimeData,
      suffix: [
        I18n.year.tr,
        I18n.month.tr,
        I18n.day.tr,
        I18n.hour.tr,
        I18n.minute.tr,
        I18n.seconds.tr,
      ],
    );
  }
}

class DateTimePicker extends DateTimePickerBase {
  DateTimePicker({
    super.key,
    required super.value,
    required super.onChange,
    super.hoverStyle,
    super.notHoverStyle,
  });

  @override
  State<StatefulWidget> createState() => DateTimePickerState();
}

class DateTimePickerState extends DateTimePickerBaseState {
  @override
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      data: dateTimeData,
      selectData: prePrecess(value),
      onConfirm: onConfirm,
      suffix: [
        I18n.year.tr,
        I18n.month.tr,
        I18n.day.tr,
        I18n.hour.tr,
        I18n.minute.tr,
        I18n.seconds.tr,
      ],
    );
  }

  dynamic onConfirm(List<dynamic> p, List<int> position) {
    final year = dateTimeData[0][position[0]];
    final month = dateTimeData[1][position[1]];
    final day = dateTimeData[2][position[2]];
    final hour = dateTimeData[3][position[3]];
    final minute = dateTimeData[4][position[4]];
    final seconds = dateTimeData[5][position[5]];
    widget.onChange('$year-$month-$day $hour:$minute:$seconds');
  }

  List prePrecess(dynamic value) {
    List result = [0, 0, 0, 0, 0, 0];
    if (value is String) {
      result = value.split(RegExp(r'\D+'));
    }
    return result;
  }
}
