part of 'script_service.dart';

extension ScriptServiceAutoX on ScriptService {
  // 自动启动脚本时，执行中使用常驻进度提示，完成后切换为普通成功提示。
  Future<void> autoRunScript() async {
    if (autoScriptList.isEmpty) return;
    final scriptList = List.of(autoScriptList);
    final psController = Get.put<ProgressSnackbarController>(
      ProgressSnackbarController(titleText: I18n.autoRunScript.tr),
    );
    psController.show();
    const minDelay = Duration(seconds: 4);
    final successScriptList = <String>[];
    for (final scriptName in scriptList) {
      var success = false;
      if (isRunning(scriptName)) {
        success = true;
      } else {
        await startScript(scriptName);
        var progress = 0.0;
        final taskStartTime = DateTime.now();
        try {
          success = await TimeoutUtils.runWithTimeout(
            period: const Duration(milliseconds: 30),
            timeout: const Duration(seconds: 6),
            check: () =>
                _checkStartSuccess(scriptName, taskStartTime, minDelay),
            onTick: () {
              if (progress + 0.005 >= 1) return;
              psController.updateMessage(scriptName);
              psController.updateProgress(progress += 0.005);
            },
          );
        } catch (e) {
          success = false;
          printError(info: 'auto run script $scriptName error: $e');
        }
        psController.updateProgress(success ? 1 : 0);
      }
      if (success) successScriptList.add(scriptName);
    }
    psController.closeSnackbar();
    _showAutoRunSuccessSnackbar(successScriptList);
  }

  // 只有存在成功结果时，才展示默认时长的成功反馈。
  void _showAutoRunSuccessSnackbar(List<String> successScriptList) {
    if (successScriptList.isEmpty) return;
    Get.snackbar(
      I18n.autoRunScript.tr,
      '$successScriptList ${I18n.startSuccess.tr}',
    );
  }

  // 同时满足脚本运行中和最小展示时长，才认定自动启动成功。
  bool _checkStartSuccess(
    String scriptName,
    DateTime taskStartTime,
    Duration minDelay,
  ) {
    final scriptModel = scriptModelMap[scriptName];
    if (scriptModel == null) {
      return false;
    }
    final isRun = scriptModel.state.value == ScriptState.running;
    final elapsedSinceStart = DateTime.now().difference(taskStartTime);
    final timeArrived = elapsedSinceStart >= minDelay;
    return isRun && timeArrived;
  }

  void updateAutoScript(String script, bool? isSelected) {
    if (isSelected == null) return;
    if (isSelected) {
      autoScriptList.add(script);
    } else {
      autoScriptList.remove(script);
    }
    autoScriptList.sort();
    _storage.write(StorageKey.autoScriptList.name, jsonEncode(autoScriptList));
  }

  void _loadAutoScriptListFromStorage() {
    final raw = _storage.read(StorageKey.autoScriptList.name);
    if (raw is List) {
      autoScriptList.value = raw.map((e) => e.toString()).toList();
      return;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          autoScriptList.value = decoded.map((e) => e.toString()).toList();
          return;
        }
      } catch (_) {}
    }
    autoScriptList.clear();
  }
}
