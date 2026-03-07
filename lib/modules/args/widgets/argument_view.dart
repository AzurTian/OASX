part of args;

class ArgumentView extends StatefulWidget {
  const ArgumentView({
    required this.setArgument,
    required this.getGroupName,
    required this.index,
    Key? key,
    this.scriptName,
    this.taskName,
  }) : super(key: key);

  final SetArgumentCallback setArgument;
  final String Function() getGroupName;
  final int index;
  final String? scriptName;
  final String? taskName;

  @override
  State<ArgumentView> createState() => _ArgumentViewState();
}

class _ArgumentViewState extends State<ArgumentView> {
  Timer? timer;
  bool landscape = true;

  ArgumentModel get model {
    final controller = Get.find<ArgsController>();
    final groupsModel = controller.groupsData.value[widget.getGroupName()];
    return groupsModel!.members[widget.index];
  }

  @override
  Widget build(BuildContext context) {
    landscape = MediaQuery.of(context).orientation == Orientation.landscape;
    if (landscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _title()),
          _form(),
        ],
      ).padding(bottom: 8);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_title(), _form()],
    ).padding(bottom: 8);
  }

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          model.title.tr,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (model.description != null && model.description!.isNotEmpty)
          SelectableText(
            model.description!.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _form() {
    return switch (model.type) {
      'boolean' => Checkbox(value: model.value, onChanged: onCheckboxChanged)
          .alignment(Alignment.centerLeft)
          .constrained(width: landscape ? 200 : null),
      'string' => TextFormField(
          initialValue: model.value.toString(),
          onChanged: (value) {
            timer?.cancel();
            timer = Timer(const Duration(milliseconds: 1000),
                () => onStringChanged(value));
          },
        ).constrained(width: landscape ? 200 : null),
      'multi_line' => TextFormField(
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: null,
          initialValue: model.value.toString(),
          onChanged: (value) {
            timer?.cancel();
            timer = Timer(const Duration(milliseconds: 1000),
                () => onStringChanged(value));
          },
        ).constrained(width: landscape ? 200 : null),
      'number' => TextFormField(
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[-0-9.]')),
          ],
          initialValue: model.value.toString(),
          onChanged: (value) {
            timer?.cancel();
            timer = Timer(const Duration(milliseconds: 1000),
                () => onNumberChanged(value));
          },
        ).constrained(width: landscape ? 200 : null),
      'integer' => TextFormField(
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[-0-9]')),
          ],
          initialValue: model.value.toString(),
          onChanged: (value) {
            timer?.cancel();
            timer = Timer(const Duration(milliseconds: 1000),
                () => onIntegerChanged(value));
          },
        ).constrained(width: landscape ? 200 : null),
      'enum' => DropdownButton<String>(
          isExpanded: !landscape,
          menuMaxHeight: Get.height * 0.5,
          value: model.value.toString(),
          items: model.enumEnum!
              .map<DropdownMenuItem<String>>(
                (e) => DropdownMenuItem(
                  value: e.toString(),
                  child: Text(
                    e.toString().tr,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ).constrained(width: landscape ? 177 : null),
                ),
              )
              .toList(),
          onChanged: onEnumChanged,
        ),
      'date_time' => DateTimePicker(
          value: model.value,
          onChange: onDateTimeChanged,
        ).constrained(width: landscape ? 200 : null),
      'time_delta' => TimeDeltaPicker(
          value: ensureTimeDeltaString(model.value),
          onChange: onTimeDeltaChanged,
        ).constrained(width: landscape ? 200 : null),
      'time' => TimePicker(
          value: model.value,
          onChange: onTimeChanged,
        ).constrained(width: landscape ? 200 : null),
      _ =>
        Text(model.value.toString()).constrained(width: landscape ? 200 : null),
    };
  }
}
