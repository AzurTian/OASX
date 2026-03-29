// ignore_for_file: invalid_use_of_protected_member
part of 'home_script_card.dart';

extension _HomeScriptCardActions on _HomeScriptCardState {
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
      saveArgumentOverride: (config, task, group, argument, type, value) {
        return widget.onSetTaskArgument(
          config,
          task,
          group,
          argument,
          type,
          value,
        );
      },
    );
  }
}

