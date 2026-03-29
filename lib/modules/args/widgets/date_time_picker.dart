// ignore_for_file: must_be_immutable

part of args;

final dateDaysInWeek =
    List.generate(7, (index) => index < 10 ? '0$index' : '$index').toList();
final dateHours =
    List.generate(24, (index) => index < 10 ? '0$index' : '$index').toList();
final dateMinutes =
    List.generate(60, (index) => index < 10 ? '0$index' : '$index').toList();
final dateSeconds =
    List.generate(60, (index) => index < 10 ? '0$index' : '$index').toList();

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
    final now = DateTime.now();
    final minDate = DateTime(now.year - 1, 1, 1);
    final maxDate = DateTime(now.year + 1, 12, 31, 23, 59, 59);
    Pickers.showDatePicker(
      context,
      mode: DateMode.YMDHMS,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      suffix: Suffix(
        years: I18n.year.tr,
        month: I18n.month.tr,
        days: I18n.day.tr,
        hours: I18n.hour.tr,
        minutes: I18n.minute.tr,
        seconds: I18n.seconds.tr,
      ),
      minDate: PDuration.parse(minDate),
      maxDate: PDuration.parse(maxDate),
      selectDate: _clampSelectedDate(value, minDate, maxDate),
      onConfirm: (p) => widget.onChange(_formatPickerValue(p)),
    );
  }

  PDuration _clampSelectedDate(
    dynamic value,
    DateTime minDate,
    DateTime maxDate,
  ) {
    final parsed = _parsePickerValue(value) ?? DateTime.now();
    final normalized = parsed.isBefore(minDate)
        ? minDate
        : parsed.isAfter(maxDate)
            ? maxDate
            : parsed;
    return PDuration.parse(normalized);
  }

  DateTime? _parsePickerValue(dynamic value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
  }

  String _formatPickerValue(PDuration value) {
    final year = value.year ?? 0;
    final month = _twoDigits(value.month);
    final day = _twoDigits(value.day);
    final hour = _twoDigits(value.hour);
    final minute = _twoDigits(value.minute);
    final second = _twoDigits(value.second);
    return '$year-$month-$day $hour:$minute:$second';
  }

  String _twoDigits(int? value) {
    final normalized = value ?? 0;
    return normalized < 10 ? '0$normalized' : '$normalized';
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

class DateTimePickerState extends DateTimePickerBaseState {}
