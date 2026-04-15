import 'dart:async';

import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/api/sse_client.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/script_statistics_models.dart';
import 'package:oasx/utils/platform_utils.dart';

/// Drives statistics state for the active script workbench.
class HomeStatisticsController extends GetxController {
  /// Dashboard controller used to resolve the active script and tab.
  final HomeDashboardController dashboardController =
      Get.find<HomeDashboardController>();

  /// Current stream state shown by the statistics header.
  final connectionState = ScriptStatisticsConnectionState.idle.obs;

  /// Latest user-visible error message.
  final lastErrorMessage = ''.obs;

  /// Whether the available dates list is loading.
  final datesLoading = false.obs;

  /// Whether one selected-date snapshot request is loading.
  final statisticsLoading = false.obs;

  /// Available backend-provided dates for the active script.
  final availableDateKeys = <String>[].obs;

  /// Selected-date statistics currently rendered by the page.
  final statistics = Rxn<ScriptStatisticsDay>();

  /// Date currently selected in the header control.
  final selectedDateKey = ''.obs;

  /// Task currently focused in the chart.
  final selectedTaskName = ''.obs;

  /// Metric currently shown by the chart.
  final historyMetric = ScriptStatisticsChartMetric.totalDuration.obs;

  /// Sort field currently applied to the chart.
  final historySortField = ScriptStatisticsChartSortField.data.obs;

  /// Whether chart values are sorted descending.
  final historySortDescending = true.obs;

  /// Whether the chart is waiting for a metric refresh.
  final historyChartLoading = false.obs;

  /// Task name highlighted by realtime updates.
  final latestUpdatedTaskName = ''.obs;

  /// Monotonic token used to restart flash animations.
  final latestUpdatedTaskPulse = 0.obs;

  /// Worker that keeps the controller bound to dashboard context.
  Worker? _dashboardWorker;

  /// Active SSE service, only present when today is selected.
  ApiSseClient? _streamService;

  /// Script currently bound by the statistics tab.
  String _boundScriptName = '';

  /// Script currently owned by the live SSE stream.
  String _streamScriptName = '';

  /// Date currently owned by the live SSE stream.
  String _streamDateKey = '';

  /// Sequence used to invalidate stale bootstrap work.
  int _bindingRevision = 0;

  /// Sequence used to invalidate stale stats work.
  int _statsRevision = 0;

  /// Sequence used to show chart metric loading transitions.
  int _historyMetricRequestId = 0;

  /// Cache key for sorted chart entries.
  String _taskEntriesCacheKey = '';

  /// Cached chart entries for the last derived state.
  List<MapEntry<String, ScriptTaskStatistics>> _taskEntriesCache = const [];

  /// Sequential queue that preserves SSE event ordering during async parsing.
  Future<void> _streamEventQueue = Future<void>.value();

  @override
  void onInit() {
    _dashboardWorker = everAll([
      dashboardController.activeScriptName,
      dashboardController.activeWorkbenchTab,
      dashboardController.activeWorkbenchSidebarTab,
      dashboardController.workbenchLayoutMode,
    ], (_) {
      unawaited(syncStatisticsBinding());
    });
    unawaited(syncStatisticsBinding());
    super.onInit();
  }

  @override
  void onClose() {
    _dashboardWorker?.dispose();
    _dashboardWorker = null;
    unawaited(_stopStream());
    super.onClose();
  }

  /// Whether the selected date is today.
  bool get isTodaySelected {
    return isStatisticsDateToday(selectedDateKey.value);
  }

  /// Whether the selected day can use time-based sorting.
  bool get canSortByTime {
    return statistics.value != null;
  }

  /// Sorted chart entries for the currently selected day.
  List<MapEntry<String, ScriptTaskStatistics>> get historyTaskEntries {
    final currentStatistics = statistics.value;
    if (currentStatistics == null) {
      return const [];
    }
    final metric = historyMetric.value;
    final sortField = historySortField.value;
    final descending = historySortDescending.value;
    final cacheKey =
        '${currentStatistics.dateKey}|${currentStatistics.totalRuntimeSeconds}|${metric.name}|${sortField.name}|$descending';
    if (_taskEntriesCacheKey == cacheKey) {
      return _taskEntriesCache;
    }
    final entries = currentStatistics.tasks.entries.where((entry) {
      if (statisticsMetricUsesBattleFilter(metric)) {
        return entry.value.battleCount > 0;
      }
      return entry.value.runCount > 0;
    }).toList();
    entries.sort((left, right) {
      final compareValue = switch (sortField) {
        ScriptStatisticsChartSortField.data => left.value
            .metricValueFor(metric)
            .compareTo(right.value.metricValueFor(metric)),
        ScriptStatisticsChartSortField.time => _compareLatestRunTime(
            left.value,
            right.value,
          ),
      };
      if (compareValue != 0) {
        return descending ? -compareValue : compareValue;
      }
      return left.key.compareTo(right.key);
    });
    _taskEntriesCacheKey = cacheKey;
    _taskEntriesCache =
        List<MapEntry<String, ScriptTaskStatistics>>.unmodifiable(entries);
    return _taskEntriesCache;
  }

  /// Run details for the focused task, sorted from newest to oldest.
  List<ScriptTaskRunRecord> get selectedHistoryDetailRuns {
    final currentStatistics = statistics.value;
    final taskName = selectedTaskName.value.trim();
    if (currentStatistics == null || taskName.isEmpty) {
      return const [];
    }
    final runs = List<ScriptTaskRunRecord>.from(
      currentStatistics.tasks[taskName]?.runs ?? const [],
    );
    runs.removeWhere((run) => !run.hasTimeRange);
    runs.sort((left, right) {
      final leftTime = left.endTime ?? left.startTime;
      final rightTime = right.endTime ?? right.startTime;
      if (leftTime == null && rightTime == null) {
        return 0;
      }
      if (leftTime == null) {
        return 1;
      }
      if (rightTime == null) {
        return -1;
      }
      return rightTime.compareTo(leftTime);
    });
    return runs;
  }

  /// Rebinds the statistics transport to the currently visible script context.
  Future<void> syncStatisticsBinding() async {
    final scriptName = dashboardController.activeScriptName.value.trim();
    if (!dashboardController.isStatsVisibleInCurrentLayout ||
        scriptName.isEmpty) {
      await _resetBindingState(clearSelection: false);
      return;
    }
    if (_boundScriptName == scriptName && availableDateKeys.isNotEmpty) {
      return;
    }
    await _bootstrapForScript(scriptName);
  }

  /// Updates the selected date and reloads its data.
  void selectHistoryDate(String dateKey) {
    if (selectedDateKey.value == dateKey ||
        !availableDateKeys.contains(dateKey) ||
        _boundScriptName.isEmpty) {
      return;
    }
    selectedDateKey.value = dateKey;
    unawaited(_loadSelectedDate(_boundScriptName, dateKey));
  }

  /// Updates the focused task in the chart.
  void selectHistoryTask(String taskName) {
    selectedTaskName.value = taskName.trim();
  }

  /// Updates the chart sort field.
  void selectHistorySortField(ScriptStatisticsChartSortField field) {
    final resolvedField =
        field == ScriptStatisticsChartSortField.time && !canSortByTime
            ? ScriptStatisticsChartSortField.data
            : field;
    if (historySortField.value == resolvedField) {
      return;
    }
    historySortField.value = resolvedField;
    _syncSelections();
  }

  /// Toggles the chart sort direction.
  void toggleHistorySortDirection() {
    historySortDescending.value = !historySortDescending.value;
    _syncSelections();
  }

  /// Updates the chart metric with a visible loading state.
  Future<void> selectHistoryMetric(ScriptStatisticsChartMetric metric) async {
    if (historyMetric.value == metric) {
      return;
    }
    final requestId = ++_historyMetricRequestId;
    historyMetric.value = metric;
    _syncSelections();
    historyChartLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (requestId != _historyMetricRequestId) {
      return;
    }
    historyChartLoading.value = false;
  }

  /// Loads dates first, then binds the newest available selected date.
  Future<void> _bootstrapForScript(String scriptName) async {
    final bindingRevision = ++_bindingRevision;
    _boundScriptName = scriptName;
    await _stopStream();
    _resetDerivedState();
    datesLoading.value = true;
    statisticsLoading.value = false;
    connectionState.value = ScriptStatisticsConnectionState.idle;
    lastErrorMessage.value = '';
    try {
      final dateList = await ApiClient().getScriptStatisticsDates(scriptName);
      if (!_isBindingActive(bindingRevision, scriptName)) {
        return;
      }
      availableDateKeys.assignAll(dateList.dates);
      datesLoading.value = false;
      if (availableDateKeys.isEmpty) {
        selectedDateKey.value = '';
        statistics.value = null;
        return;
      }
      selectedDateKey.value = availableDateKeys.first;
      await _loadSelectedDate(scriptName, selectedDateKey.value);
    } catch (error) {
      if (!_isBindingActive(bindingRevision, scriptName)) {
        return;
      }
      datesLoading.value = false;
      availableDateKeys.clear();
      selectedDateKey.value = '';
      statistics.value = null;
      lastErrorMessage.value = error.toString();
    }
  }

  /// Loads the currently selected date using either SSE or one-shot HTTP.
  Future<void> _loadSelectedDate(String scriptName, String dateKey) async {
    if (_boundScriptName != scriptName ||
        !availableDateKeys.contains(dateKey)) {
      return;
    }
    final shouldUseLiveStream =
        isStatisticsDateToday(dateKey) && !PlatformUtils.isWeb;
    final statsRevision = ++_statsRevision;
    await _stopStream();
    _resetSelectedDateState();
    lastErrorMessage.value = '';
    if (shouldUseLiveStream) {
      statisticsLoading.value = false;
      await _startTodayStream(scriptName, dateKey, statsRevision);
      return;
    }
    connectionState.value = ScriptStatisticsConnectionState.idle;
    statisticsLoading.value = true;
    try {
      final day = await ApiClient().getScriptStatisticsDay(scriptName, dateKey);
      if (!_isStatsRequestActive(statsRevision, scriptName, dateKey)) {
        return;
      }
      statisticsLoading.value = false;
      statistics.value = day;
      connectionState.value =
          isStatisticsDateToday(dateKey) && PlatformUtils.isWeb
              ? ScriptStatisticsConnectionState.connected
              : ScriptStatisticsConnectionState.idle;
      _syncSelections();
    } catch (error) {
      if (!_isStatsRequestActive(statsRevision, scriptName, dateKey)) {
        return;
      }
      statisticsLoading.value = false;
      statistics.value = null;
      connectionState.value =
          isStatisticsDateToday(dateKey) && PlatformUtils.isWeb
              ? ScriptStatisticsConnectionState.error
              : ScriptStatisticsConnectionState.idle;
      lastErrorMessage.value = error.toString();
    }
  }

  /// Starts the live SSE stream for today.
  Future<void> _startTodayStream(
    String scriptName,
    String dateKey,
    int statsRevision,
  ) async {
    if (!_isStatsRequestActive(statsRevision, scriptName, dateKey)) {
      return;
    }
    _streamScriptName = scriptName;
    _streamDateKey = dateKey;
    final sseUri = ApiClient().buildScriptStatisticsSseUri(scriptName, dateKey);
    _streamService = ApiSseClient(
      url: sseUri,
      onEvent: _handleStreamEvent,
      onStateChanged: _handleStreamState,
    );
    await _streamService?.connect();
  }

  /// Stops the current statistics stream.
  Future<void> _stopStream() async {
    final service = _streamService;
    _streamService = null;
    _streamScriptName = '';
    _streamDateKey = '';
    _streamEventQueue = Future<void>.value();
    await service?.dispose();
  }

  /// Resets state when the tab is hidden or script becomes unavailable.
  Future<void> _resetBindingState({required bool clearSelection}) async {
    _bindingRevision++;
    _statsRevision++;
    _boundScriptName = '';
    await _stopStream();
    datesLoading.value = false;
    statisticsLoading.value = false;
    connectionState.value = ScriptStatisticsConnectionState.idle;
    lastErrorMessage.value = '';
    availableDateKeys.clear();
    statistics.value = null;
    latestUpdatedTaskName.value = '';
    latestUpdatedTaskPulse.value = 0;
    historySortField.value = ScriptStatisticsChartSortField.data;
    historySortDescending.value = true;
    historyChartLoading.value = false;
    _clearDerivedCaches();
    if (clearSelection) {
      selectedDateKey.value = '';
      selectedTaskName.value = '';
    }
  }

  /// Resets derived state for a new bound script.
  void _resetDerivedState() {
    availableDateKeys.clear();
    statistics.value = null;
    selectedDateKey.value = '';
    selectedTaskName.value = '';
    latestUpdatedTaskName.value = '';
    latestUpdatedTaskPulse.value = 0;
    historySortField.value = ScriptStatisticsChartSortField.data;
    historySortDescending.value = true;
    historyChartLoading.value = false;
    _clearDerivedCaches();
  }

  /// Resets selected-date data before a reload starts.
  void _resetSelectedDateState() {
    statistics.value = null;
    selectedTaskName.value = '';
    latestUpdatedTaskName.value = '';
    latestUpdatedTaskPulse.value = 0;
    _clearDerivedCaches();
  }

  /// Updates the visible stream state and error label.
  void _handleStreamState(ApiSseConnectionState state, String? message) {
    if (_streamService == null || !isTodaySelected) {
      return;
    }
    final normalizedMessage = message == 'stream_closed' ? '' : (message ?? '');
    connectionState.value = switch (state) {
      ApiSseConnectionState.connecting =>
        ScriptStatisticsConnectionState.connecting,
      ApiSseConnectionState.connected =>
        ScriptStatisticsConnectionState.connected,
      ApiSseConnectionState.reconnecting =>
        ScriptStatisticsConnectionState.reconnecting,
      ApiSseConnectionState.error => ScriptStatisticsConnectionState.error,
    };
    lastErrorMessage.value = normalizedMessage;
    if (state == ApiSseConnectionState.error &&
        lastErrorMessage.value.isNotEmpty) {
      printError(info: 'stats[$_streamScriptName] ${lastErrorMessage.value}');
    }
  }

  /// Merges live SSE events into the selected-day state.
  void _handleStreamEvent(ApiSseEvent event) {
    _streamEventQueue = _streamEventQueue.then(
      (_) => _processStreamEvent(event),
      onError: (_) => _processStreamEvent(event),
    );
  }

  /// Parses and applies one SSE event without blocking the UI isolate.
  Future<void> _processStreamEvent(ApiSseEvent event) async {
    final streamService = _streamService;
    final dateKey = _streamDateKey;
    if (streamService == null || dateKey.isEmpty) {
      return;
    }
    final payloadText = event.data.trim();
    if (payloadText.isEmpty) {
      return;
    }
    try {
      switch (event.name.trim()) {
        case 'snapshot':
          final day = await parseScriptStatisticsSnapshotPayloadAsync(
            payloadText,
            dateKey: dateKey,
          );
          if (_streamService != streamService || _streamDateKey != dateKey) {
            return;
          }
          statistics.value = day;
          latestUpdatedTaskName.value = '';
          _clearDerivedCaches();
          _syncSelections();
          break;
        case 'update':
          final update = await parseScriptStatisticsUpdatePayloadAsync(
            payloadText,
          );
          if (_streamService != streamService || _streamDateKey != dateKey) {
            return;
          }
          final currentStatistics = statistics.value;
          if (currentStatistics == null ||
              currentStatistics.dateKey != dateKey) {
            return;
          }
          statistics.value = currentStatistics.applyUpdate(update);
          _markUpdatedTask(update.changedTasks);
          _clearDerivedCaches();
          _syncSelections();
          break;
        default:
          return;
      }
      connectionState.value = ScriptStatisticsConnectionState.connected;
      lastErrorMessage.value = '';
    } catch (error) {
      printError(
        info: 'stats[$_streamScriptName] parse event "${event.name}": $error',
      );
    }
  }

  /// Keeps the focused task valid when selected-date content changes.
  void _syncSelections() {
    final entries = historyTaskEntries;
    if (entries.isEmpty) {
      selectedTaskName.value = '';
      return;
    }
    if (!canSortByTime &&
        historySortField.value == ScriptStatisticsChartSortField.time) {
      historySortField.value = ScriptStatisticsChartSortField.data;
    }
    final preferredTask = selectedTaskName.value.trim();
    final hasPreferredTask = entries.any((entry) => entry.key == preferredTask);
    selectedTaskName.value =
        hasPreferredTask ? preferredTask : entries.first.key;
  }

  /// Clears cached derived lists used by the chart.
  void _clearDerivedCaches() {
    _taskEntriesCacheKey = '';
    _taskEntriesCache = const [];
  }

  /// Marks the latest updated task for a flash highlight.
  void _markUpdatedTask(Map<String, ScriptTaskStatistics> changedTasks) {
    if (changedTasks.isEmpty) {
      return;
    }
    final latestEntry = changedTasks.entries.toList()
      ..sort((left, right) {
        final leftTime = left.value.latestRunStartTime;
        final rightTime = right.value.latestRunStartTime;
        if (leftTime == null && rightTime == null) {
          return 0;
        }
        if (leftTime == null) {
          return 1;
        }
        if (rightTime == null) {
          return -1;
        }
        return rightTime.compareTo(leftTime);
      });
    latestUpdatedTaskName.value = latestEntry.first.key;
    latestUpdatedTaskPulse.value++;
  }

  /// Returns whether one bootstrap run is still active.
  bool _isBindingActive(int revision, String scriptName) {
    return revision == _bindingRevision &&
        dashboardController.isStatsVisibleInCurrentLayout &&
        _boundScriptName == scriptName &&
        dashboardController.activeScriptName.value.trim() == scriptName;
  }

  /// Returns whether one selected-date request is still active.
  bool _isStatsRequestActive(
    int revision,
    String scriptName,
    String dateKey,
  ) {
    return revision == _statsRevision &&
        dashboardController.isStatsVisibleInCurrentLayout &&
        _boundScriptName == scriptName &&
        selectedDateKey.value == dateKey;
  }

  /// Compares tasks by their latest run start time.
  int _compareLatestRunTime(
    ScriptTaskStatistics left,
    ScriptTaskStatistics right,
  ) {
    final leftTime = left.latestRunStartTime;
    final rightTime = right.latestRunStartTime;
    if (leftTime == null && rightTime == null) {
      return 0;
    }
    if (leftTime == null) {
      return -1;
    }
    if (rightTime == null) {
      return 1;
    }
    return leftTime.compareTo(rightTime);
  }
}
