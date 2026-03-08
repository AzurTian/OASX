import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/common/controllers/progress_snackbar_controller.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/home/models/script_model.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/extension_utils.dart';
import 'package:oasx/utils/time_utils.dart';
import 'package:oasx/modules/overview/index.dart';

part 'script_service_ws.dart';
part 'script_service_auto.dart';

class ScriptService extends GetxService {
  // ignore: unused_field
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
            Get.delete<OverviewController>(tag: e, force: true),
          ])),
    ]);
    scriptModelMap.clear();
    super.onClose();
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
        Get.snackbar(
          I18n.tip.tr,
          I18n.configUpdateTip.tr,
          duration: const Duration(milliseconds: 2000),
        );
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
}


