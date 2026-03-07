import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/modules/home/home_script_actions.dart';
import 'package:oasx/modules/home/widgets/home_constants.dart';
import 'package:oasx/modules/home/widgets/home_task_manager_dialog.dart';
import 'package:oasx/modules/home/widgets/home_task_summary.dart';

part 'home_script_card_actions.dart';
part 'home_script_card_view.dart';
part 'home_script_card_state_indicator.dart';

class HomeScriptCard extends StatefulWidget {
  const HomeScriptCard({
    super.key,
    required this.scriptModel,
    required this.scriptService,
    required this.onOpenLog,
    required this.taskListHeight,
    required this.onTaskListTap,
    required this.showLinkCheckbox,
    required this.isLinked,
    required this.onLinkedChanged,
    required this.onTogglePower,
    required this.onSetTaskArgument,
    required this.onOpenTaskSettings,
  });

  final ScriptModel scriptModel;
  final ScriptService scriptService;
  final VoidCallback onOpenLog;
  final double taskListHeight;
  final VoidCallback onTaskListTap;
  final bool showLinkCheckbox;
  final bool isLinked;
  final ValueChanged<bool> onLinkedChanged;
  final Future<void> Function(bool enable) onTogglePower;
  final HomeTaskArgumentSetter onSetTaskArgument;
  final void Function(String scriptName, String taskName) onOpenTaskSettings;

  @override
  State<HomeScriptCard> createState() => _HomeScriptCardState();
}

class _HomeScriptCardState extends State<HomeScriptCard>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  late final AnimationController _deleteHoldController;
  bool _isEditingName = false;
  bool _isSubmittingRename = false;
  bool _isDeleteDialogShowing = false;
  String? _editingOriginalName;

  @override
  void initState() {
    super.initState();
    _deleteHoldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      reverseDuration: const Duration(milliseconds: 180),
    )..addStatusListener(_onDeleteHoldStatusChanged);
    _nameFocusNode.addListener(_handleNameFocusChanged);
  }

  @override
  void didUpdateWidget(covariant HomeScriptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingName) {
      _nameController.text = widget.scriptModel.name;
    }
  }

  @override
  void dispose() {
    _deleteHoldController
      ..removeStatusListener(_onDeleteHoldStatusChanged)
      ..dispose();
    _nameFocusNode.removeListener(_handleNameFocusChanged);
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildCard(context);
}


