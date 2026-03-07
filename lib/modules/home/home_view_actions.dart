// ignore_for_file: invalid_use_of_protected_member
part of 'index.dart';

extension _HomeViewActions on _HomeViewState {
  Widget _buildDashboardBody() {
    return Column(
      children: [
        Obx(() => HomeOverviewHeader(
              scriptService: scriptService,
              loadingAddScript: _isAddingScript,
              refreshingScripts: _isRefreshingScripts,
              onAddScriptTap: _onAddScriptCardTap,
              onRefreshScriptsTap: _onRefreshScriptsTap,
              isLinkModeEnabled: controller.isLinkModeEnabled.value,
              onToggleLinkMode: controller.toggleLinkMode,
            )),
        Expanded(
          child: Obx(() {
            if (controller.startupLoadingMessage.value.isNotEmpty) {
              return const SizedBox.expand();
            }
            final scripts = _orderedScripts();
            if (controller.isStartupConnectionFailed.value) {
              return _buildConnectionFailedView();
            }
            if (scripts.isEmpty) {
              return _buildConnectionFailedView();
            }
            return HomeScriptGrid(
              scripts: scripts,
              scriptService: scriptService,
              onOpenLog: _openLogPage,
              isLinkModeEnabled: controller.isLinkModeEnabled.value,
              linkedScripts: controller.validLinkedScripts,
              onLinkedChanged: controller.setScriptLinked,
              onToggleScriptPower: _toggleScriptPower,
              onSetTaskArgument: _setTaskArgument,
              onOpenTaskSettings: _openTaskSettings,
              bottomReservedSpace:
                  widget.standalone ? kHomeSettingsFabReservedSpace : 0,
            );
          }),
        ),
      ],
    );
  }

  Widget _buildConnectionFailedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              if (controller.isStartupChecking.value) {
                return const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                );
              }
              return Icon(
                Icons.cloud_off_rounded,
                size: 34,
                color: Theme.of(context).colorScheme.outline,
              );
            }),
            const SizedBox(height: 12),
            Text(
              I18n.homeConnectionRetryHint.tr,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<ScriptModel> _orderedScripts() {
    final orderedNames = scriptService.scriptOrderList;
    final scriptMap = scriptService.scriptModelMap;
    final orderedScripts = <ScriptModel>[];
    for (final name in orderedNames) {
      final model = scriptMap[name];
      if (model != null) {
        orderedScripts.add(model);
      }
    }
    return orderedScripts;
  }

  Future<void> _onAddScriptCardTap() async {
    if (_isAddingScript) {
      return;
    }
    await showAddConfigDialog(
      context,
      onSubmitting: () {
        if (!mounted) return;
        setState(() {
          _isAddingScript = true;
        });
      },
      onSubmitDone: () {
        if (!mounted) return;
        setState(() {
          _isAddingScript = false;
        });
      },
    );
  }

  Future<void> _onRefreshScriptsTap() async {
    if (_isRefreshingScripts) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isRefreshingScripts = true;
    });
    try {
      await controller.retryStartupConnection();
      controller.setControlScripts(controller.validControlScripts);
    } catch (_) {
      Get.snackbar(I18n.loginError.tr, I18n.loginErrorMsg.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingScripts = false;
        });
      }
    }
  }

  void _openLogPage(String scriptName) {
    Get.toNamed('/overview', parameters: {'script': scriptName});
  }

  Future<void> _toggleScriptPower(String scriptName, bool enable) async {
    await controller.applyLinkedPowerToggle(
      sourceScript: scriptName,
      enable: enable,
    );
  }

  Future<bool> _setTaskArgument(
    String scriptName,
    String taskName,
    String group,
    String argument,
    String type,
    dynamic value,
  ) async {
    return controller.applyLinkedSetArgument(
      config: scriptName,
      task: taskName,
      group: group,
      argument: argument,
      type: type,
      value: value,
    );
  }

  void _openTaskSettings(String scriptName, String taskName) {
    HomeTaskSettingsDialog.show(
      scriptName: scriptName,
      taskName: taskName,
      setArgumentOverride: (config, task, group, argument, type, value) {
        unawaited(
          controller.applyLinkedSetArgument(
            config: config,
            task: task,
            group: group,
            argument: argument,
            type: type,
            value: value,
          ),
        );
      },
    );
  }
}

