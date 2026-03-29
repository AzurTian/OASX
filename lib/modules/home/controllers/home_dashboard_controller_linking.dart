part of 'home_dashboard_controller.dart';

extension HomeDashboardLinkingX on HomeDashboardController {
  void toggleLinkMode() {
    final next = !isLinkModeEnabled.value;
    isLinkModeEnabled.value = next;
    if (!next) {
      linkedScriptList.clear();
    }
  }

  void setScriptLinked(String scriptName, bool linked) {
    if (!isLinkModeEnabled.value) {
      return;
    }
    final name = scriptName.trim();
    if (name.isEmpty) {
      return;
    }
    final updated = linkedScriptList.toSet();
    if (linked) {
      updated.add(name);
    } else {
      updated.remove(name);
    }
    linkedScriptList.value = updated.toList()..sort();
  }

  bool isScriptLinked(String scriptName) {
    return linkedScriptList.contains(scriptName.trim());
  }

  List<String> get validLinkedScripts => linkedScriptList
      .where((name) => _scriptService.scriptModelMap.containsKey(name))
      .toSet()
      .toList()
    ..sort();

  List<String> linkedScopeScriptsFor(String sourceScript) {
    return _collectCascadeTargets(sourceScript);
  }

  bool shouldCascadeFrom(String sourceScript) {
    final source = sourceScript.trim();
    if (!isLinkModeEnabled.value || source.isEmpty) {
      return false;
    }
    return validLinkedScripts.contains(source);
  }

  Future<void> applyLinkedPowerToggle({
    required String sourceScript,
    required bool enable,
  }) async {
    final targets = _collectCascadeTargets(sourceScript);
    for (final name in targets) {
      if (enable) {
        await _scriptService.startScript(name);
      } else {
        await _scriptService.stopScript(name);
      }
    }
  }

  Future<bool> applyLinkedSetArgument({
    required String? config,
    required String? task,
    required String group,
    required String argument,
    required String type,
    required dynamic value,
  }) async {
    final source = (config ?? '').trim();
    if (source.isEmpty) {
      return false;
    }
    final argsController = Get.find<ArgsController>();
    var allSuccess = true;
    final targets = _collectCascadeTargets(source);
    for (final target in targets) {
      final ret = await argsController.setArgument(
        target,
        task,
        group,
        argument,
        type,
        value,
      );
      allSuccess = ret && allSuccess;
    }
    return allSuccess;
  }

  List<String> _collectCascadeTargets(String sourceScript) {
    final source = sourceScript.trim();
    if (source.isEmpty) {
      return const [];
    }
    if (!shouldCascadeFrom(source)) {
      return [source];
    }
    final targets = validLinkedScripts.toSet();
    if (!targets.contains(source)) {
      return [source];
    }
    return targets.toList()..sort();
  }
}

