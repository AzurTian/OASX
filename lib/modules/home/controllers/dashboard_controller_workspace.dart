part of 'dashboard_controller.dart';

extension HomeDashboardWorkspaceX on HomeDashboardController {
  /// Records the latest resolved workbench layout mode.
  void setWorkbenchLayoutMode(HomeWorkbenchLayoutMode value) {
    if (workbenchLayoutMode.value == value) {
      return;
    }
    workbenchLayoutMode.value = value;
  }

  bool canQuickScheduleTask(ScriptModel model, String taskName) {
    final normalized = taskName.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final runningTaskName = model.runningTask.value.taskName.value.trim();
    final isConfigRunning = model.state.value == ScriptState.running;
    return !isConfigRunning || runningTaskName != normalized;
  }

  List<HomeWorkbenchTab> workbenchTabsFor(HomeWorkbenchLayoutMode mode) {
    return resolveHomeWorkbenchTabs(mode);
  }

  List<HomeWorkbenchTab> workbenchSidebarTabsFor(
    HomeWorkbenchLayoutMode mode,
  ) {
    return resolveHomeWorkbenchSidebarTabs(mode);
  }

  HomeWorkbenchTab displayedWorkbenchTabFor(HomeWorkbenchLayoutMode mode) {
    if (mode == HomeWorkbenchLayoutMode.threePane &&
        isHomeWorkbenchSidebarTab(activeWorkbenchTab.value)) {
      return _lastPrimaryWorkbenchTab.value;
    }
    return activeWorkbenchTab.value;
  }

  HomeWorkbenchTab displayedWorkbenchSidebarTabFor(
    HomeWorkbenchLayoutMode mode,
  ) {
    return activeWorkbenchSidebarTab.value;
  }

  bool get isStatsVisibleInCurrentLayout {
    if (workbenchLayoutMode.value == HomeWorkbenchLayoutMode.threePane) {
      return displayedWorkbenchSidebarTabFor(workbenchLayoutMode.value) ==
          HomeWorkbenchTab.stats;
    }
    return activeWorkbenchTab.value == HomeWorkbenchTab.stats;
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
    activeScriptName.value = normalized;
  }

  void showScriptListPage() {
    clearActiveTask();
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
    if (isHomeWorkbenchSidebarTab(value)) {
      activeWorkbenchSidebarTab.value = value;
    } else {
      _lastPrimaryWorkbenchTab.value = value;
    }
    if (value != HomeWorkbenchTab.tasks) {
      clearActiveTask();
    }
    activeWorkbenchTab.value = value;
  }

  void setActiveWorkbenchSidebarTabValue(HomeWorkbenchTab value) {
    if (!isHomeWorkbenchSidebarTab(value)) {
      return;
    }
    activeWorkbenchSidebarTab.value = value;
    if (workbenchLayoutMode.value != HomeWorkbenchLayoutMode.threePane) {
      setActiveWorkbenchTabValue(value);
    }
  }

  void setTaskCatalogFilterValue(HomeTaskCatalogFilter value) {
    taskCatalogFilter.value = value;
  }

  void openTaskParameters(
    String taskName, {
    required HomeTaskParameterEntrySource source,
  }) {
    final normalized = taskName.trim();
    if (normalized.isEmpty) {
      return;
    }
    activeTaskName.value = normalized;
    _taskParameterEntrySource.value = source;
    activeWorkbenchTab.value = HomeWorkbenchTab.tasks;
  }

  void clearActiveTask() {
    activeTaskName.value = '';
    _taskParameterEntrySource.value = null;
  }

  Future<void> closeTaskParameters() async {
    final returnTab = switch (_taskParameterEntrySource.value) {
      HomeTaskParameterEntrySource.overview => HomeWorkbenchTab.status,
      HomeTaskParameterEntrySource.tasks || null => HomeWorkbenchTab.tasks,
    };
    clearActiveTask();
    _lastPrimaryWorkbenchTab.value = returnTab;
    activeWorkbenchTab.value = returnTab;
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
    if (!runNow) {
      return syncTaskNextRun(
        scriptName: scriptName,
        taskName: taskName,
      );
    }
    final targetDt = formatDateTime(
      DateTime.now().add(const Duration(days: -1)),
    );
    return updateTaskNextRun(
      scriptName: scriptName,
      taskName: taskName,
      nextRun: targetDt,
    );
  }

  Future<bool> updateTaskNextRun({
    required String scriptName,
    required String taskName,
    required String nextRun,
  }) async {
    final source = scriptName.trim();
    final normalizedTask = taskName.trim();
    final normalizedNextRun = nextRun.trim();
    if (source.isEmpty || normalizedTask.isEmpty || normalizedNextRun.isEmpty) {
      return false;
    }
    final argsController = Get.find<ArgsController>();
    return _applyTaskActionAcrossLinkedScope(
      sourceScript: source,
      taskName: normalizedTask,
      action: (target, resolvedTask) {
        return argsController.updateScriptTaskNextRun(
          target,
          resolvedTask,
          normalizedNextRun,
        );
      },
    );
  }

  /// Routes one quick wait action through the dedicated sync endpoint.
  Future<bool> syncTaskNextRun({
    required String scriptName,
    required String taskName,
    String targetDt = '',
  }) async {
    final source = scriptName.trim();
    final normalizedTask = taskName.trim();
    if (source.isEmpty || normalizedTask.isEmpty) {
      return false;
    }
    return _applyTaskActionAcrossLinkedScope(
      sourceScript: source,
      taskName: normalizedTask,
      action: (target, resolvedTask) {
        return ApiClient().syncScriptTaskNextRun(
          scriptName,
          taskName,
          targetDt,
        );
      },
    );
  }

  Future<bool> quickToggleTaskEnabled({
    required String scriptName,
    required String taskName,
    required bool enable,
  }) async {
    return toggleTaskEnabled(
      scriptName: scriptName,
      taskName: taskName,
      enable: enable,
    );
  }

  /// Toggles one task enable flag, optionally across the linked scope.
  Future<bool> toggleTaskEnabled({
    required String scriptName,
    required String taskName,
    required bool enable,
    bool applyLinkedScope = true,
  }) async {
    final source = scriptName.trim();
    final normalizedTask = taskName.trim();
    if (source.isEmpty || normalizedTask.isEmpty) {
      return false;
    }
    final argsController = Get.find<ArgsController>();
    if (!applyLinkedScope) {
      return argsController.updateScriptTask(source, normalizedTask, enable);
    }
    return _applyTaskActionAcrossLinkedScope(
      sourceScript: source,
      taskName: normalizedTask,
      action: (target, resolvedTask) {
        return argsController.updateScriptTask(target, resolvedTask, enable);
      },
    );
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

  Future<bool> _applyTaskActionAcrossLinkedScope({
    required String sourceScript,
    required String taskName,
    required Future<bool> Function(String scriptName, String taskName) action,
  }) async {
    final source = sourceScript.trim();
    final normalizedTask = taskName.trim();
    if (source.isEmpty || normalizedTask.isEmpty) {
      return false;
    }
    final targets = await _resolveLinkedTaskTargets(source, normalizedTask);
    if (targets.isEmpty) {
      return false;
    }
    var allSuccess = true;
    for (final target in targets) {
      final ret = await action(target, normalizedTask);
      allSuccess = ret && allSuccess;
    }
    return allSuccess;
  }

  Future<List<String>> _resolveLinkedTaskTargets(
    String sourceScript,
    String taskName,
  ) async {
    final source = sourceScript.trim();
    final normalizedTask = taskName.trim();
    if (source.isEmpty || normalizedTask.isEmpty) {
      return const [];
    }
    final scopeTargets = linkedScopeScriptsFor(source);
    if (scopeTargets.length <= 1) {
      return scopeTargets;
    }
    if (!scopeTargets.contains(source)) {
      return [source];
    }
    final targets = <String>[source];
    for (final target in scopeTargets) {
      if (target == source) {
        continue;
      }
      if (await _scriptContainsTask(target, normalizedTask)) {
        targets.add(target);
      }
    }
    return targets;
  }

  Future<bool> _scriptContainsTask(String scriptName, String taskName) async {
    final normalizedScript = scriptName.trim();
    final normalizedTask = taskName.trim();
    if (normalizedScript.isEmpty || normalizedTask.isEmpty) {
      return false;
    }
    final cacheKey = '$normalizedScript::$normalizedTask';
    final cached = _taskAvailabilityCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final taskData = await ApiClient().getScriptTask(
      normalizedScript,
      normalizedTask,
    );
    final supported = taskData.isNotEmpty;
    _taskAvailabilityCache[cacheKey] = supported;
    return supported;
  }

  void _ensureActiveScript(List<ScriptModel> candidates) {
    final current = activeScriptName.value.trim();
    final validNames = candidates.map((item) => item.name).toSet();
    if (current.isNotEmpty && validNames.contains(current)) {
      return;
    }
    if (candidates.isEmpty) {
      clearActiveTask();
      activeScriptName.value = '';
      workbenchPage.value = HomeWorkbenchPage.scripts;
      return;
    }
    activeScriptName.value = candidates.isEmpty ? '' : candidates.first.name;
  }
}
