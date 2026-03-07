part of 'script_service.dart';

extension ScriptServiceAutoX on ScriptService {
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
        startScript(scriptName);
        var progress = 0.0;
        final taskStartTime = DateTime.now();
        success = await TimeoutUtils.runWithTimeout(
          period: const Duration(milliseconds: 30),
          timeout: const Duration(seconds: 6),
          check: () => _checkStartSuccess(scriptName, taskStartTime, minDelay),
          onTick: () {
            if (progress + 0.005 >= 1) return;
            psController.updateMessage(scriptName);
            psController.updateProgress(progress += 0.005);
          },
        );
        psController.updateProgress(success ? 1 : 0);
      }
      if (success) successScriptList.add(scriptName);
    }
    psController.updateMessage('$successScriptList ${I18n.startSuccess.tr}');
  }

  bool _checkStartSuccess(
    String scriptName,
    DateTime taskStartTime,
    Duration minDelay,
  ) {
    final isRun = scriptModelMap[scriptName]!.state.value == ScriptState.running;
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
