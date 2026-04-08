part of 'script_service.dart';

extension ScriptServiceConfigX on ScriptService {
  /// Syncs one updated config list and connects the target config immediately.
  Future<void> syncScriptsAndConnect({
    required Iterable<String> scripts,
    required String configName,
  }) async {
    syncScriptOrder(scripts);
    await _connectKnownConfig(configName);
  }

  /// Renames one config and rebuilds its realtime runtime under the new name.
  Future<bool> renameConfig(String oldName, String newName) async {
    final ret = await ApiClient().renameConfig(oldName, newName);
    if (!ret) {
      return false;
    }
    await _disposeConfigRuntime(oldName);
    await refreshScriptsFromServer();
    await _connectKnownConfig(newName);
    return true;
  }

  /// Deletes one config and clears its cached runtime context.
  Future<bool> deleteConfig(String name) async {
    final ret = await ApiClient().deleteConfig(name);
    if (!ret) {
      return false;
    }
    await _disposeConfigRuntime(name);
    await refreshScriptsFromServer();
    return true;
  }

  /// Connects one config only when it is present in the synced config list.
  Future<void> _connectKnownConfig(String configName) async {
    final normalized = configName.trim();
    if (normalized.isEmpty || !scriptOrderList.contains(normalized)) {
      return;
    }
    await connectScript(normalized);
  }

  /// Clears one config websocket, log controller, and cached model state.
  Future<void> _disposeConfigRuntime(String configName) async {
    final normalized = configName.trim();
    if (normalized.isEmpty) {
      return;
    }
    await wsService.close(normalized);
    if (Get.isRegistered<ScriptLogController>(tag: normalized)) {
      try {
        Get.delete<ScriptLogController>(tag: normalized, force: true);
      } catch (_) {}
    }
    scriptModelMap.remove(normalized);
    autoScriptList.removeWhere((item) => item == normalized);
    scriptOrderList.removeWhere((item) => item == normalized);
  }
}
