part of 'home_dashboard_controller.dart';

extension HomeDashboardWorkspaceX on HomeDashboardController {
  List<HomeWorkbenchTab> workbenchTabsFor(HomeWorkbenchLayoutMode mode) {
    if (mode == HomeWorkbenchLayoutMode.threePane) {
      return const [HomeWorkbenchTab.status, HomeWorkbenchTab.tasks];
    }
    return HomeWorkbenchTab.values;
  }

  HomeWorkbenchTab displayedWorkbenchTabFor(HomeWorkbenchLayoutMode mode) {
    if (mode == HomeWorkbenchLayoutMode.threePane &&
        activeWorkbenchTab.value == HomeWorkbenchTab.logs) {
      return _lastPrimaryWorkbenchTab.value;
    }
    return activeWorkbenchTab.value;
  }

  List<ScriptModel> get orderedScripts {
    final models = <ScriptModel>[];
    for (final name in _scriptService.scriptOrderList) {
      final model = _scriptService.findScriptModel(name);
      if (model != null) {
        models.add(model);
      }
    }
    return models;
  }

  List<ScriptModel> get visibleScripts {
    return orderedScripts.where(_matchesVisibleFilter).toList();
  }

  ScriptModel? get activeScriptModel {
    return _scriptService.findScriptModel(activeScriptName.value.trim());
  }

  List<String> get selectedScopeScripts {
    final active = activeScriptName.value.trim();
    return active.isEmpty ? const [] : [active];
  }

  int get selectedScopeCount => selectedScopeScripts.length;

  bool get isSinglePaneScriptListPage =>
      workbenchPage.value == HomeWorkbenchPage.scripts;

  int countScriptsByState(HomeScriptStateFilter filter) {
    return orderedScripts
        .where((model) => scriptCollectionStateFor(model) == filter)
        .length;
  }

  bool isScriptSelected(String scriptName) {
    return selectedScriptList.contains(scriptName.trim());
  }

  Set<String> enabledTaskNamesFor(ScriptModel model) {
    final names = <String>{};
    final running = model.runningTask.value.taskName.value.trim();
    if (running.isNotEmpty) {
      names.add(running);
    }
    names.addAll(
      model.pendingTaskList
          .map((task) => task.taskName.value.trim())
          .where((taskName) => taskName.isNotEmpty),
    );
    names.addAll(
      model.waitingTaskList
          .map((task) => task.taskName.value.trim())
          .where((taskName) => taskName.isNotEmpty),
    );
    return names;
  }

  bool isTaskEnabled(ScriptModel model, String taskName) {
    final normalized = taskName.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return enabledTaskNamesFor(model).contains(normalized);
  }

  HomeScriptStateFilter scriptStateFor(ScriptModel model) {
    return switch (model.state.value) {
      ScriptState.running => HomeScriptStateFilter.running,
      ScriptState.warning => HomeScriptStateFilter.abnormal,
      ScriptState.inactive => HomeScriptStateFilter.stopped,
      ScriptState.updating => HomeScriptStateFilter.offline,
    };
  }

  HomeScriptStateFilter scriptCollectionStateFor(ScriptModel model) {
    return switch (model.state.value) {
      ScriptState.running => HomeScriptStateFilter.running,
      ScriptState.warning => HomeScriptStateFilter.abnormal,
      ScriptState.inactive => HomeScriptStateFilter.stopped,
      ScriptState.updating => HomeScriptStateFilter.abnormal,
    };
  }

  void setSearchQuery(String value) {
    searchQuery.value = value.trim().toLowerCase();
    _ensureActiveScript(visibleScripts);
  }

  void setStateFilterValue(HomeScriptStateFilter value) {
    stateFilter.value = value;
    _ensureActiveScript(visibleScripts);
  }

  void setActiveScript(String scriptName) {
    final normalized = scriptName.trim();
    if (normalized.isEmpty) {
      return;
    }
    if (activeScriptName.value == normalized) {
      return;
    }
    activeTaskName.value = '';
    activeScriptName.value = normalized;
  }

  void showScriptListPage() {
    workbenchPage.value = HomeWorkbenchPage.scripts;
  }

  void showWorkspacePage() {
    if (activeScriptName.value.trim().isEmpty) {
      return;
    }
    workbenchPage.value = HomeWorkbenchPage.workspace;
  }

  void toggleScriptSelected(String scriptName, bool selected) {
    final normalized = scriptName.trim();
    if (normalized.isEmpty) {
      return;
    }
    final updated = selectedScriptList.toSet();
    if (selected) {
      updated.add(normalized);
      activeScriptName.value = normalized;
    } else {
      updated.remove(normalized);
      if (activeScriptName.value == normalized) {
        final next = updated.isEmpty ? '' : updated.first;
        activeScriptName.value = next;
      }
    }
    selectedScriptList.value = updated.toList()..sort();
    _ensureActiveScript(visibleScripts);
  }

  void clearSelectedScripts() {
    selectedScriptList.clear();
    _ensureActiveScript(visibleScripts);
  }

  void setActiveWorkbenchTabValue(HomeWorkbenchTab value) {
    if (value != HomeWorkbenchTab.logs) {
      _lastPrimaryWorkbenchTab.value = value;
    }
    if (value != HomeWorkbenchTab.tasks) {
      activeTaskName.value = '';
    }
    activeWorkbenchTab.value = value;
  }

  void setTaskCatalogFilterValue(HomeTaskCatalogFilter value) {
    taskCatalogFilter.value = value;
  }

  void setActiveTask(String taskName, {bool openParams = false}) {
    activeTaskName.value = taskName.trim();
    if (openParams) {
      _lastPrimaryWorkbenchTab.value = HomeWorkbenchTab.tasks;
      activeWorkbenchTab.value = HomeWorkbenchTab.tasks;
    }
  }

  void clearActiveTask() {
    activeTaskName.value = '';
  }

  void syncWorkspaceState() {
    _ensureActiveScript(visibleScripts);
  }

  Future<void> applySelectionPowerToggle({
    required String sourceScript,
    required bool enable,
  }) async {
    for (final name in _resolveScopeTargets(sourceScript)) {
      if (enable) {
        await _scriptService.startScript(name);
      } else {
        await _scriptService.stopScript(name);
      }
    }
  }

  Future<bool> applySelectionSetArgument({
    required String? config,
    required String? task,
    required String group,
    required String argument,
    required String type,
    required dynamic value,
  }) async {
    final source = (config ?? '').trim();
    if (source.isEmpty || task == null || task.isEmpty) {
      return false;
    }
    final argsController = Get.find<ArgsController>();
    var allSuccess = true;
    for (final target in _resolveScopeTargets(source)) {
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

  Future<bool> quickScheduleTask({
    required String scriptName,
    required String taskName,
    required bool runNow,
  }) async {
    final targetDt = formatDateTime(
      DateTime.now().add(Duration(days: runNow ? -1 : 1)),
    );
    var allSuccess = true;
    for (final name in _resolveScopeTargets(scriptName)) {
      final ret = await ApiClient().syncNextRun(
        name,
        taskName,
        targetDt: targetDt,
      );
      if (ret) {
        await Get.find<WebSocketService>().send(name, 'get_schedule');
      }
      allSuccess = ret && allSuccess;
    }
    return allSuccess;
  }

  Future<bool> quickToggleTaskEnabled({
    required String scriptName,
    required String taskName,
    required bool enable,
  }) async {
    final argsController = Get.find<ArgsController>();
    var allSuccess = true;
    for (final name in _resolveScopeTargets(scriptName)) {
      final ret = await argsController.updateScriptTask(name, taskName, enable);
      allSuccess = ret && allSuccess;
    }
    return allSuccess;
  }

  bool _matchesVisibleFilter(ScriptModel model) {
    final query = searchQuery.value.trim();
    final stateMatched = stateFilter.value == HomeScriptStateFilter.all ||
        scriptCollectionStateFor(model) == stateFilter.value;
    if (!stateMatched) {
      return false;
    }
    if (query.isEmpty) {
      return true;
    }
    return model.name.toLowerCase().contains(query);
  }

  List<String> _resolveScopeTargets(String sourceScript) {
    final source = sourceScript.trim();
    return source.isEmpty ? const [] : [source];
  }

  void _ensureActiveScript(List<ScriptModel> candidates) {
    final current = activeScriptName.value.trim();
    final validNames = candidates.map((item) => item.name).toSet();
    if (current.isNotEmpty && validNames.contains(current)) {
      return;
    }
    if (candidates.isEmpty) {
      activeScriptName.value = '';
      workbenchPage.value = HomeWorkbenchPage.scripts;
      return;
    }
    activeScriptName.value = candidates.isEmpty ? '' : candidates.first.name;
  }
}
