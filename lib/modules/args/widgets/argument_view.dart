part of args;

class ArgumentView extends StatefulWidget {
  const ArgumentView({
    required this.setArgument,
    required this.getGroupName,
    required this.index,
    this.lockImmediateScheduling = false,
    Key? key,
    this.scriptName,
    this.taskName,
  }) : super(key: key);

  final SetArgumentCallback setArgument;
  final String Function() getGroupName;
  final int index;
  final bool lockImmediateScheduling;
  final String? scriptName;
  final String? taskName;

  @override
  State<ArgumentView> createState() => _ArgumentViewState();
}

class _ArgumentViewState extends State<ArgumentView> {
  Timer? timer;
  bool landscape = true;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  ArgumentModel get model {
    final controller = Get.find<ArgsController>();
    final groupsModel = controller.groupsData.value[widget.getGroupName()];
    return groupsModel!.members[widget.index];
  }

  ArgsController get _argsController => Get.find<ArgsController>();

  bool get _isProtectedImmediateScheduleField {
    return widget.lockImmediateScheduling &&
        ArgsController.isImmediateSchedulingField(
          widget.getGroupName(),
          model.title,
        );
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: model.value.toString());
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    timer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      landscape = MediaQuery.of(context).orientation == Orientation.landscape;
      _syncTextController();
      final title = _title();
      final form = _buildFormSection();
      if (landscape) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            Expanded(child: form),
          ],
        ).padding(bottom: 8);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, form],
      ).padding(bottom: 8);
    });
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
          ).padding(top: 4),
      ],
    );
  }

  Widget _buildFormSection() {
    final errorText =
        _argsController.fieldError(widget.getGroupName(), model.title);
    final isLocked = _isProtectedImmediateScheduleField;
    final child = switch (model.type) {
      'boolean' => Checkbox(
          value: model.value,
          onChanged: isLocked ? null : onCheckboxChanged,
        ).alignment(Alignment.centerLeft),
      'string' => _buildTextField(errorText: errorText, enabled: !isLocked),
      'multi_line' => _buildTextField(
          errorText: errorText,
          maxLines: null,
          enabled: !isLocked,
        ),
      'number' => _buildTextField(
          errorText: errorText,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[-0-9.]')),
          ],
          onChanged: _scheduleNumberChange,
          enabled: !isLocked,
        ),
      'integer' => _buildTextField(
          errorText: errorText,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[-0-9]')),
          ],
          onChanged: _scheduleIntegerChange,
          enabled: !isLocked,
        ),
      'enum' => DropdownButtonFormField<String>(
          initialValue: model.value.toString(),
          isExpanded: true,
          menuMaxHeight: Get.height * 0.5,
          decoration: InputDecoration(errorText: errorText),
          items: model.enumEnum!
              .map<DropdownMenuItem<String>>(
                (e) => DropdownMenuItem(
                  value: e.toString(),
                  child: Text(
                    e.toString().tr,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => model.enumEnum!
              .map<Widget>(
                (e) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    e.toString().tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
              .toList(),
          onChanged: isLocked ? null : onEnumChanged,
        ),
      'date_time' => _buildPicker(
          DateTimePicker(value: model.value, onChange: onDateTimeChanged),
          errorText,
          enabled: !isLocked,
        ),
      'time_delta' => _buildPicker(
          TimeDeltaPicker(
            value: ensureTimeDeltaString(model.value),
            onChange: onTimeDeltaChanged,
          ),
          errorText,
          enabled: !isLocked,
        ),
      'time' => _buildPicker(
          TimePicker(value: model.value, onChange: onTimeChanged),
          errorText,
          enabled: !isLocked,
        ),
      _ => Text(model.value.toString()),
    };
    return child;
  }

  Widget _buildTextField({
    required String? errorText,
    bool enabled = true,
    int? maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isSingleLine = maxLines == 1;
    return TextFormField(
      controller: _textController,
      focusNode: _focusNode,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      scrollPadding: EdgeInsets.only(
        left: 12,
        top: 12,
        right: 12,
        bottom: keyboardInset > 0 ? keyboardInset + 24 : 24,
      ),
      textInputAction:
          isSingleLine ? TextInputAction.done : TextInputAction.newline,
      decoration: InputDecoration(errorText: errorText),
      onTapOutside:
          PlatformUtils.isWeb ? null : (_) => _focusNode.unfocus(),
      onEditingComplete: PlatformUtils.isWeb
          ? null
          : (isSingleLine ? _focusNode.unfocus : null),
      onChanged: onChanged ?? _scheduleStringChange,
    );
  }

  Widget _buildPicker(
    Widget picker,
    String? errorText, {
    bool enabled = true,
  }) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            picker,
            if (errorText != null && errorText.isNotEmpty)
              Text(
                errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ).padding(top: 4),
          ],
        ),
      ),
    );
  }

  void _syncTextController() {
    if (_focusNode.hasFocus) {
      return;
    }
    final nextValue = model.value.toString();
    if (_textController.text == nextValue) {
      return;
    }
    _textController.value = TextEditingValue(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
  }

  void _scheduleStringChange(String value) {
    timer?.cancel();
    timer =
        Timer(const Duration(milliseconds: 150), () => onStringChanged(value));
  }

  void _scheduleNumberChange(String value) {
    timer?.cancel();
    timer =
        Timer(const Duration(milliseconds: 150), () => onNumberChanged(value));
  }

  void _scheduleIntegerChange(String value) {
    timer?.cancel();
    timer =
        Timer(const Duration(milliseconds: 150), () => onIntegerChanged(value));
  }
}
