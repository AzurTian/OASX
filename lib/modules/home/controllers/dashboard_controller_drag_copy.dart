part of 'dashboard_controller.dart';

extension HomeDashboardDragCopyX on HomeDashboardController {
  /// Returns whether drag-copy is available in the current layout.
  bool get canUseDesktopDragCopy {
    return workbenchLayoutMode.value != HomeWorkbenchLayoutMode.singlePane;
  }

  /// Returns whether the config is currently handling one drag-copy request.
  bool isDragCopyPendingFor(String configName) {
    return pendingDragCopyTargets.contains(configName.trim());
  }

  /// Builds one task-row drag payload for the active config workspace.
  ConfigDragPayload buildTaskDragPayload({
    required String sourceConfig,
    required String taskName,
  }) {
    return ConfigDragPayload.task(
      sourceConfigName: sourceConfig.trim(),
      taskName: taskName.trim(),
    );
  }

  /// Builds one task-group drag payload for the task parameter workspace.
  ConfigDragPayload buildGroupDragPayload({
    required String sourceConfig,
    required String taskName,
    required String groupName,
  }) {
    return ConfigDragPayload.group(
      sourceConfigName: sourceConfig.trim(),
      taskName: taskName.trim(),
      groupName: groupName.trim(),
    );
  }

  /// Builds one task-catalog group payload for the active config workspace.
  ConfigDragPayload buildTaskCatalogGroupDragPayload({
    required String sourceConfig,
    required String groupName,
    required List<String> taskNames,
  }) {
    return ConfigDragPayload.taskCatalogGroup(
      sourceConfigName: sourceConfig.trim(),
      groupName: groupName.trim(),
      taskNames: taskNames
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }

  /// Records the payload currently being dragged.
  void startConfigDrag(ConfigDragPayload payload) {
    activeDragPayload.value = payload;
  }

  /// Clears the current drag payload after the session ends.
  void clearConfigDrag() {
    activeDragPayload.value = null;
  }

  /// Executes the copy action for an accepted drop target.
  Future<bool> acceptConfigDrag({
    required ConfigDragPayload payload,
    required String destinationConfig,
  }) async {
    final normalizedDestination = destinationConfig.trim();
    if (!payload.canDropOn(normalizedDestination) ||
        isDragCopyPendingFor(normalizedDestination)) {
      return false;
    }
    _setDragCopyPending(normalizedDestination, true);
    try {
      final ret = await _runDragCopyRequest(
        payload: payload,
        destinationConfig: normalizedDestination,
      );
      if (!ret) {
        return false;
      }
      await _refreshCopiedConfigs([normalizedDestination]);
      Get.snackbar(I18n.success.tr, payload.displayLabel.tr);
      return true;
    } finally {
      _setDragCopyPending(normalizedDestination, false);
    }
  }

  /// Executes the backend copy request with one timeout guard.
  Future<bool> _runDragCopyRequest({
    required ConfigDragPayload payload,
    required String destinationConfig,
  }) async {
    return switch (payload.kind) {
      ConfigDragKind.task => ApiClient().copyTask(
          payload.taskName,
          destinationConfig,
          payload.sourceConfigName,
        ),
      ConfigDragKind.group => ApiClient().copyGroup(
          payload.taskName,
          payload.groupName,
          destinationConfig,
          payload.sourceConfigName,
        ),
      ConfigDragKind.taskCatalogGroup => _copyTaskCatalogGroup(
          payload,
          destinationConfig,
        ),
    };
  }

  /// Copies every task contained in one dragged task-catalog group.
  Future<bool> _copyTaskCatalogGroup(
    ConfigDragPayload payload,
    String destinationConfig,
  ) async {
    if (payload.taskNames.isEmpty) {
      return false;
    }
    for (final taskName in payload.taskNames) {
      final ret = await ApiClient().copyTask(
        taskName,
        destinationConfig,
        payload.sourceConfigName,
      );
      if (!ret) {
        return false;
      }
    }
    return true;
  }

  /// Adds or removes one config from the in-flight drag-copy target set.
  void _setDragCopyPending(String configName, bool pending) {
    final normalized = configName.trim();
    if (normalized.isEmpty) {
      return;
    }
    final next = pendingDragCopyTargets.toSet();
    if (pending) {
      next.add(normalized);
    } else {
      next.remove(normalized);
    }
    pendingDragCopyTargets.value = next.toList()..sort();
  }

  /// Requests fresh schedule data for destination configs affected by one copy.
  Future<void> _refreshCopiedConfigs(Iterable<String> configNames) async {
    final targets = configNames
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    for (final name in targets) {
      _invalidateTaskAvailabilityCache(name);
      if (_scriptService.findScriptModel(name) == null) {
        continue;
      }
      await _scriptService.wsService.send(name, 'get_schedule');
    }
    syncWorkspaceState();
  }

  /// Clears cached task-availability answers for one copied destination config.
  void _invalidateTaskAvailabilityCache(String configName) {
    final normalized = configName.trim();
    if (normalized.isEmpty) {
      return;
    }
    final cachePrefix = '$normalized::';
    _taskAvailabilityCache.removeWhere(
      (cacheKey, _) => cacheKey.startsWith(cachePrefix),
    );
  }
}
