import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/home/home_script_actions.dart';
import 'package:oasx/views/home/widgets/home_constants.dart';
import 'package:oasx/views/home/widgets/home_task_manager_dialog.dart';
import 'package:oasx/views/home/widgets/home_task_summary.dart';

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

  void _handleNameFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      _submitRenameOnBlur();
    }
  }

  void _startEditingName() {
    if (_isSubmittingRename || _isEditingName || _isDeleteDialogShowing) {
      return;
    }
    _deleteHoldController.reset();
    final currentName = widget.scriptModel.name;
    setState(() {
      _isEditingName = true;
      _editingOriginalName = currentName;
      _nameController.text = currentName;
      _nameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _nameController.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nameFocusNode.requestFocus();
    });
  }

  Future<void> _submitRenameOnBlur() async {
    if (!_isEditingName || _isSubmittingRename) {
      return;
    }
    final oldName = _editingOriginalName ?? widget.scriptModel.name;
    final newName = _nameController.text.trim();
    if (newName == oldName) {
      if (!mounted) return;
      setState(() {
        _isEditingName = false;
        _editingOriginalName = null;
      });
      return;
    }

    final error = HomeScriptActions.validateRenameName(
      oldName: oldName,
      newName: newName,
      scriptService: widget.scriptService,
    );
    if (error != null) {
      if (mounted) {
        Get.snackbar(I18n.error.tr, error);
        setState(() {
          _nameController.text = oldName;
          _isEditingName = false;
          _editingOriginalName = null;
        });
      }
      return;
    }

    setState(() {
      _isSubmittingRename = true;
    });
    final success = await HomeScriptActions.renameScript(
      scriptService: widget.scriptService,
      oldName: oldName,
      newName: newName,
    );
    if (!mounted) return;

    setState(() {
      if (!success) {
        _nameController.text = oldName;
      }
      _isSubmittingRename = false;
      _isEditingName = false;
      _editingOriginalName = null;
    });
  }

  void _onDeleteHoldStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    unawaited(_showDeleteDialogAfterHold());
  }

  Future<void> _showDeleteDialogAfterHold() async {
    if (_isDeleteDialogShowing || _isEditingName || _isSubmittingRename) {
      return;
    }
    _isDeleteDialogShowing = true;
    await HomeScriptActions.showDeleteDialog(
      scriptService: widget.scriptService,
      name: widget.scriptModel.name,
    );
    _isDeleteDialogShowing = false;
    if (!mounted) return;
    _deleteHoldController.reset();
  }

  void _startDeleteHold() {
    if (_isEditingName || _isSubmittingRename || _isDeleteDialogShowing) {
      return;
    }
    _deleteHoldController.forward(from: 0);
  }

  void _cancelDeleteHold() {
    if (_deleteHoldController.status == AnimationStatus.completed) {
      return;
    }
    if (_deleteHoldController.value > 0) {
      _deleteHoldController.reverse();
    }
  }

  Future<void> _openTaskManager() async {
    await HomeTaskManagerDialog.show(
      context: context,
      scriptName: widget.scriptModel.name,
      setArgumentOverride: (config, task, group, argument, type, value) {
        if (config == null || task == null) {
          return;
        }
        unawaited(widget.onSetTaskArgument(
          config,
          task,
          group,
          argument,
          type,
          value,
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: homeScriptCardHeight(widget.taskListHeight),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Obx(() {
            final state = widget.scriptModel.state.value;
            final isRunning = state == ScriptState.running;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.showLinkCheckbox)
                      Checkbox(
                        value: widget.isLinked,
                        visualDensity: VisualDensity.compact,
                        onChanged: (value) {
                          widget.onLinkedChanged(value ?? false);
                        },
                      ).paddingOnly(right: 2),
                    IconButton(
                      tooltip: I18n.log.tr,
                      onPressed: widget.onOpenLog,
                      icon: const Icon(Icons.article_outlined),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _startEditingName,
                        onLongPressStart: (_) => _startDeleteHold(),
                        onLongPressEnd: (_) => _cancelDeleteHold(),
                        onLongPressCancel: _cancelDeleteHold,
                        child: _isEditingName
                            ? TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 8),
                                  border: const OutlineInputBorder(),
                                  enabled: !_isSubmittingRename,
                                ),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _nameFocusNode.unfocus(),
                              ).paddingSymmetric(vertical: 1, horizontal: 4)
                            : AnimatedBuilder(
                                animation: _deleteHoldController,
                                builder: (context, child) {
                                  final progress = _deleteHoldController.value;
                                  if (progress <= 0) {
                                    return child!;
                                  }
                                  final colorScheme =
                                      Theme.of(context).colorScheme;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      child!,
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          minHeight: 4,
                                          value: progress,
                                          color: colorScheme.error,
                                          backgroundColor: colorScheme.error
                                              .withValues(alpha: 0.20),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                child: Text(
                                  widget.scriptModel.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ).paddingSymmetric(vertical: 3, horizontal: 4),
                              ),
                      ),
                    ),
                    _ScriptStateIndicator(state: state),
                    IconButton(
                      tooltip: isRunning ? I18n.stopped.tr : I18n.running.tr,
                      onPressed: () async {
                        await widget.onTogglePower(!isRunning);
                      },
                      icon: const Icon(Icons.power_settings_new_rounded),
                      isSelected: isRunning,
                    ),
                    IconButton(
                      onPressed: _openTaskManager,
                      icon: const Icon(Icons.playlist_add_check_rounded),
                    ),
                  ],
                ),
                const Divider(height: 14),
                SizedBox(
                  height: widget.taskListHeight,
                  child: HomeTaskSummary(
                    scriptModel: widget.scriptModel,
                    onTapList: widget.onTaskListTap,
                    onSetTaskArgument: widget.onSetTaskArgument,
                    onOpenTaskSettings: widget.onOpenTaskSettings,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _ScriptStateIndicator extends StatelessWidget {
  const _ScriptStateIndicator({required this.state});

  final ScriptState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: switch (state) {
        ScriptState.running => const SpinKitChasingDots(
            color: Colors.green,
            size: 22,
          ),
        ScriptState.inactive =>
          const Icon(Icons.donut_large, size: 24, color: Colors.grey),
        ScriptState.warning =>
          const SpinKitDoubleBounce(color: Colors.orange, size: 24),
        ScriptState.updating => const Icon(
            Icons.browser_updated_rounded,
            size: 24,
            color: Colors.blue,
          ),
      },
    );
  }
}
