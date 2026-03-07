import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/controller/progress_snackbar_controller.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/extension_utils.dart';
import 'package:oasx/utils/time_utils.dart';
import 'package:oasx/views/overview/overview_view.dart';

class ScriptService extends GetxService {
  final _storage = GetStorage();
  final wsService = Get.find<WebSocketService>();
  final scriptModelMap = <String, ScriptModel>{}.obs;
  final scriptOrderList = <String>[].obs;
  final autoScriptList = <String>[].obs;

  @override
  Future<void> onInit() async {
    await reloadFromServer();
    _loadAutoScriptListFromStorage();
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    await autoRunScript();
    super.onReady();
  }

  @override
  Future<void> onClose() async {
    await Future.wait([
      ...scriptModelMap.keys.map((e) => Future.wait([
            stopScript(e),
            wsService.close(e),
            Get.delete<OverviewController>(tag: e, force: true)
          ])),
    ]);
    scriptModelMap.clear();
    super.onClose();
  }

  Future<void> connectScript(String name) async {
    if (!scriptModelMap.containsKey(name)) {
      addScriptModel(name);
    }
    wsService.removeAllListeners(name);
    final client =
        await wsService.connect(name: name, listener: (mg) => wsListener(mg, name));
    client.status.listen(
      (wsStatus) => scriptModelMap[name]?.update(state: wsStatus.scriptState),
    );
  }

  Future<void> startScript(String name) async {
    if (!scriptModelMap.containsKey(name)) return;
    if (isRunning(name)) return;
    await connectScript(name);
    await wsService.send(name, 'start');
  }

  void wsListener(dynamic message, String name) {
    if (message is! String) {
      printError(info: 'Websocket push data is not of type string and map');
      return;
    }
    if (!message.startsWith('{') || !message.endsWith('}')) {
      if (Get.isRegistered<OverviewController>(tag: name)) {
        Get.find<OverviewController>(tag: name).addLog(message);
      }
      return;
    }
    final data = jsonDecode(message) as Map<String, dynamic>;
    if (data.containsKey('state')) {
      scriptModelMap[name]!.update(state: ScriptState.getState(data['state']));
      return;
    }
    if (!data.containsKey('schedule')) {
      return;
    }

    final run = data['schedule']['running'] as Map;
    final pending = data['schedule']['pending'] as List<dynamic>;
    final waiting = data['schedule']['waiting'] as List<dynamic>;
    final runningTask = run.isNotEmpty
        ? TaskItemModel(name, run['name'], run['next_run'])
        : TaskItemModel.empty();
    final pendingList =
        pending.map((e) => TaskItemModel(name, e['name'], e['next_run'])).toList();
    final waitingList =
        waiting.map((e) => TaskItemModel(name, e['name'], e['next_run'])).toList();
    scriptModelMap[name]!.update(
      runningTask: runningTask,
      pendingTaskList: pendingList,
      waitingTaskList: waitingList,
    );
  }

  Future<void> stopScript(String name) async {
    if (!scriptModelMap.containsKey(name)) return;
    await wsService.send(name, 'stop');
  }

  void addScriptModel(dynamic sm) {
    if (sm is String) {
      sm = ScriptModel(sm);
    }
    if (scriptModelMap.containsKey(sm.name)) return;
    scriptModelMap[sm.name] = sm;
    if (!scriptOrderList.contains(sm.name)) {
      scriptOrderList.add(sm.name);
    }
  }

  void updateScriptModel(ScriptModel sm) {
    if (!scriptModelMap.containsKey(sm.name)) return;
    scriptModelMap[sm.name] = sm;
  }

  void addOrUpdateScriptModel(ScriptModel sm) {
    if (scriptModelMap.containsKey(sm.name)) {
      updateScriptModel(sm);
    } else {
      addScriptModel(sm);
    }
  }

  void deleteScriptModel(String name) {
    if (!scriptModelMap.containsKey(name)) return;
    scriptModelMap.remove(name);
    wsService.close(name);
    autoScriptList.removeWhere((e) => e == name);
    scriptOrderList.removeWhere((e) => e == name);
  }

  void syncScriptOrder(Iterable<String> scripts) {
    final normalized = scripts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    scriptOrderList.value = normalized;
    for (final name in normalized) {
      if (!scriptModelMap.containsKey(name)) {
        addScriptModel(name);
      }
    }
    final validSet = normalized.toSet();
    final stale = scriptModelMap.keys.where((e) => !validSet.contains(e)).toList();
    for (final name in stale) {
      deleteScriptModel(name);
    }
  }

  ScriptModel? findScriptModel(String name) {
    return scriptModelMap[name];
  }

  bool isRunning(String scriptName) {
    return scriptModelMap.containsKey(scriptName) &&
        scriptModelMap[scriptName]!.state.value == ScriptState.running;
  }

  Future<bool> tryCloseScriptWithReason(String scriptName) async {
    try {
      final scriptModel = findScriptModel(scriptName);
      if (scriptModel != null && scriptModel.state.value == ScriptState.running) {
        Get.snackbar(I18n.tip.tr, I18n.config_update_tip.tr,
            duration: const Duration(milliseconds: 2000));
        return false;
      }
      await wsService.close(scriptName);
      return true;
    } catch (e) {
      if (e.toString().contains('not found')) {
        return true;
      }
      return false;
    }
  }

  Future<void> refreshScriptsFromServer() async {
    final latest = await ApiClient().getScriptList();
    syncScriptOrder(latest);
  }

  Future<void> reloadFromServer() async {
    final scriptList = await ApiClient().getScriptList();
    syncScriptOrder(scriptList);
    if (scriptList.isEmpty) {
      return;
    }
    await Future.wait(scriptList.map((name) => connectScript(name)));
  }

  Future<void> resetDashboardState() async {
    await wsService.closeAll();
    final names = scriptModelMap.keys.toList();
    for (final name in names) {
      if (Get.isRegistered<OverviewController>(tag: name)) {
        try {
          Get.delete<OverviewController>(tag: name, force: true);
        } catch (_) {}
      }
    }
    scriptModelMap.clear();
    scriptOrderList.clear();
  }

  Future<bool> renameConfig(String oldName, String newName) async {
    final ret = await ApiClient().renameConfig(oldName, newName);
    if (!ret) {
      return false;
    }
    if (Get.isRegistered<OverviewController>(tag: oldName)) {
      try {
        Get.delete<OverviewController>(tag: oldName, force: true);
      } catch (_) {}
    }
    await refreshScriptsFromServer();
    return true;
  }

  Future<bool> deleteConfig(String name) async {
    final ret = await ApiClient().deleteConfig(name);
    if (!ret) {
      return false;
    }
    if (Get.isRegistered<OverviewController>(tag: name)) {
      try {
        Get.delete<OverviewController>(tag: name, force: true);
      } catch (_) {}
    }
    deleteScriptModel(name);
    await refreshScriptsFromServer();
    return true;
  }

  Future<void> autoRunScript() async {
    if (autoScriptList.isEmpty) return;
    final scriptList = List.of(autoScriptList);
    final psController = Get.put<ProgressSnackbarController>(
        ProgressSnackbarController(titleText: I18n.auto_run_script.tr));
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
    psController.updateMessage('$successScriptList ${I18n.start_success.tr}');
  }

  bool _checkStartSuccess(
      String scriptName, DateTime taskStartTime, Duration minDelay) {
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
