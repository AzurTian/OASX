import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/statistics_controller.dart';
import 'package:oasx/modules/home/models/script_statistics_models.dart';
import 'package:oasx/modules/home/widgets/statistics_detail_section.dart';
import 'package:oasx/modules/home/widgets/statistics_formatters.dart';
import 'package:oasx/modules/home/widgets/statistics_history_chart.dart';
import 'package:oasx/translation/i18n_content.dart';

const _kStatisticsPanelHorizontalPadding = 12.0;
const _kStatisticsPanelSectionSpacing = 12.0;
const _kStatisticsSummarySpacing = 8.0;
const _kStatisticsDropdownBorderRadius = 10.0;
const _kStatisticsDropdownHorizontalPadding = 10.0;
const _kStatisticsDateDropdownMinWidth = 96.0;
const _kStatisticsDateMenuMaxVisibleItems = 4;

/// Main statistics tab content for the active script.
class ScriptStatisticsPanel extends StatelessWidget {
  /// Creates the statistics panel.
  const ScriptStatisticsPanel({super.key});

  /// Controller that owns statistics state.
  HomeStatisticsController get controller =>
      Get.find<HomeStatisticsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final statistics = controller.statistics.value;
      final availableDates =
          controller.availableDateKeys.toList(growable: false);
      if (statistics == null) {
        return _StatisticsPlaceholder(
          label: _placeholderLabel(),
          message: controller.lastErrorMessage.value,
          loading: _placeholderIsLoading(),
        );
      }
      final entries = controller.historyTaskEntries;
      final detailRuns = controller.selectedHistoryDetailRuns;
      final canSortByTime = controller.canSortByTime;
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          _kStatisticsPanelHorizontalPadding,
          _kStatisticsPanelSectionSpacing,
          _kStatisticsPanelHorizontalPadding,
          _kStatisticsPanelSectionSpacing,
        ),
        children: [
          _HeaderSection(
            statistics: statistics,
            availableDateKeys: availableDates,
            controller: controller,
            canSortByTime: canSortByTime,
          ),
          const SizedBox(height: _kStatisticsPanelSectionSpacing),
          _ChartCard(
            controller: controller,
            entries: entries,
            detailRuns: detailRuns,
          ),
        ],
      );
    });
  }

  /// Returns the placeholder title for the current controller state.
  String _placeholderLabel() {
    if (controller.datesLoading.value || controller.statisticsLoading.value) {
      return I18n.homeStatsLoadingMessage.tr;
    }
    if (controller.availableDateKeys.isEmpty) {
      return controller.lastErrorMessage.value.isEmpty
          ? I18n.homeStatsHistoryDateEmpty.tr
          : I18n.error.tr;
    }
    if (controller.isTodaySelected) {
      return switch (controller.connectionState.value) {
        ScriptStatisticsConnectionState.connecting =>
          I18n.homeStatsLoadingMessage.tr,
        ScriptStatisticsConnectionState.reconnecting =>
          I18n.homeStatsReconnecting.tr,
        ScriptStatisticsConnectionState.error => I18n.homeStatsStreamError.tr,
        _ => I18n.homeStatsWaitingSnapshot.tr,
      };
    }
    return controller.lastErrorMessage.value.isEmpty
        ? I18n.homeStatsChartEmpty.tr
        : I18n.error.tr;
  }

  /// Returns whether the placeholder should show a loading indicator.
  bool _placeholderIsLoading() {
    if (controller.datesLoading.value || controller.statisticsLoading.value) {
      return true;
    }
    return controller.isTodaySelected &&
        controller.connectionState.value !=
            ScriptStatisticsConnectionState.error &&
        controller.availableDateKeys.isNotEmpty;
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.statistics,
    required this.availableDateKeys,
    required this.controller,
    required this.canSortByTime,
  });

  final ScriptStatisticsDay statistics;
  final List<String> availableDateKeys;
  final HomeStatisticsController controller;
  final bool canSortByTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: _kStatisticsPanelSectionSpacing),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderTopRow(
            statistics: statistics,
            availableDateKeys: availableDateKeys,
            controller: controller,
          ),
          const SizedBox(height: _kStatisticsPanelSectionSpacing),
          _HeaderFiltersRow(
            controller: controller,
            canSortByTime: canSortByTime,
          ),
        ],
      ),
    );
  }
}

class _HeaderTopRow extends StatelessWidget {
  const _HeaderTopRow({
    required this.statistics,
    required this.availableDateKeys,
    required this.controller,
  });

  final ScriptStatisticsDay statistics;
  final List<String> availableDateKeys;
  final HomeStatisticsController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusIcon(controller: controller),
                const SizedBox(width: _kStatisticsSummarySpacing),
                _HistoryDateDropdown(
                  values: availableDateKeys,
                  selectedValue: controller.selectedDateKey.value,
                  onChanged: controller.selectHistoryDate,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: _kStatisticsSummarySpacing),
        Text(
          formatStatisticsDuration(statistics.totalRuntimeSeconds),
          textAlign: TextAlign.end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _HeaderFiltersRow extends StatelessWidget {
  const _HeaderFiltersRow({
    required this.controller,
    required this.canSortByTime,
  });

  final HomeStatisticsController controller;
  final bool canSortByTime;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: _kStatisticsSummarySpacing,
      runSpacing: _kStatisticsSummarySpacing,
      children: [
        _MetricDropdown(
          value: controller.historyMetric.value,
          onChanged: (metric) {
            controller.selectHistoryMetric(metric);
          },
        ),
        _SortFieldDropdown(
          value: controller.historySortField.value,
          allowTime: canSortByTime,
          onChanged: controller.selectHistorySortField,
        ),
        IconButton(
          onPressed: controller.toggleHistorySortDirection,
          icon: Icon(
            controller.historySortDescending.value
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.controller});

  final HomeStatisticsController controller;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _statusLabel(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _statusTone(context).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _statusTone(context).withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          _statusIcon(),
          size: 18,
          color: _statusTone(context),
        ),
      ),
    );
  }

  String _statusLabel() {
    if (controller.datesLoading.value) {
      return I18n.homeStatsLoadingMessage.tr;
    }
    if (controller.statisticsLoading.value) {
      return I18n.homeStatsLoadingMessage.tr;
    }
    if (!controller.isTodaySelected) {
      return controller.lastErrorMessage.value.isEmpty
          ? ''
          : I18n.homeStatsStreamError.tr;
    }
    return switch (controller.connectionState.value) {
      ScriptStatisticsConnectionState.connecting => '',
      ScriptStatisticsConnectionState.connected => '',
      ScriptStatisticsConnectionState.reconnecting =>
        I18n.homeStatsReconnecting.tr,
      ScriptStatisticsConnectionState.error => I18n.homeStatsStreamError.tr,
      ScriptStatisticsConnectionState.idle => '',
    };
  }

  IconData _statusIcon() {
    if (controller.lastErrorMessage.value.isNotEmpty) {
      return Icons.error_outline_rounded;
    }
    if (controller.datesLoading.value || controller.statisticsLoading.value) {
      return Icons.hourglass_top_rounded;
    }
    if (!controller.isTodaySelected) {
      return Icons.cloud_done_outlined;
    }
    return switch (controller.connectionState.value) {
      ScriptStatisticsConnectionState.connected => Icons.wifi_tethering_rounded,
      ScriptStatisticsConnectionState.reconnecting => Icons.sync_rounded,
      ScriptStatisticsConnectionState.error => Icons.error_outline_rounded,
      _ => Icons.hourglass_top_rounded,
    };
  }

  Color _statusTone(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (controller.lastErrorMessage.value.isNotEmpty ||
        controller.connectionState.value ==
            ScriptStatisticsConnectionState.error) {
      return scheme.error;
    }
    if (controller.isTodaySelected &&
        controller.connectionState.value ==
            ScriptStatisticsConnectionState.connected) {
      return Colors.teal;
    }
    return scheme.primary;
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.controller,
    required this.entries,
    required this.detailRuns,
  });

  final HomeStatisticsController controller;
  final List<MapEntry<String, ScriptTaskStatistics>> entries;
  final List<ScriptTaskRunRecord> detailRuns;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.historyChartLoading.value;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entries.isEmpty)
                Center(child: Text(I18n.homeStatsChartEmpty.tr))
              else ...[
                if (loading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
                ],
                Opacity(
                  opacity: loading ? 0.32 : 1,
                  child: IgnorePointer(
                    ignoring: loading,
                    child: ScriptStatisticsHistoryChart(
                      entries: entries,
                      metric: controller.historyMetric.value,
                      focusedTaskName: controller.selectedTaskName.value,
                      onSelectTask: controller.selectHistoryTask,
                      flashingTaskName: controller.latestUpdatedTaskName.value,
                      flashToken: controller.latestUpdatedTaskPulse.value,
                      highlightRealtimeTask: controller.isTodaySelected,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ScriptStatisticsDetailSection(
                taskName: controller.selectedTaskName.value,
                runs: detailRuns,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _MetricDropdown extends StatelessWidget {
  const _MetricDropdown({required this.value, required this.onChanged});

  final ScriptStatisticsChartMetric value;
  final ValueChanged<ScriptStatisticsChartMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = ScriptStatisticsChartMetric.values
        .map(
          (metric) => _StatisticsMenuOption(
            value: metric,
            label: _labelForMetric(metric),
          ),
        )
        .toList(growable: false);
    return _StatisticsPopupSelector<ScriptStatisticsChartMetric>(
      options: options,
      value: value,
      onChanged: onChanged,
    );
  }

  /// Resolves the dropdown label for one metric.
  String _labelForMetric(ScriptStatisticsChartMetric metric) {
    return switch (metric) {
      ScriptStatisticsChartMetric.totalDuration =>
        I18n.homeStatsTotalDuration.tr,
      ScriptStatisticsChartMetric.runCount => I18n.homeStatsMetricRunCount.tr,
      ScriptStatisticsChartMetric.battleCount =>
        I18n.homeStatsMetricBattleCount.tr,
      ScriptStatisticsChartMetric.battleAvgDuration =>
        I18n.homeStatsMetricBattleAvgDuration.tr,
      ScriptStatisticsChartMetric.avgRunDuration =>
        I18n.homeStatsMetricAvgRunDuration.tr,
    };
  }
}

class _SortFieldDropdown extends StatelessWidget {
  const _SortFieldDropdown({
    required this.value,
    required this.allowTime,
    required this.onChanged,
  });

  final ScriptStatisticsChartSortField value;
  final bool allowTime;
  final ValueChanged<ScriptStatisticsChartSortField> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <_StatisticsMenuOption<ScriptStatisticsChartSortField>>[
      _StatisticsMenuOption(
        value: ScriptStatisticsChartSortField.data,
        label: I18n.homeStatsSortByData.tr,
      ),
      if (allowTime)
        _StatisticsMenuOption(
          value: ScriptStatisticsChartSortField.time,
          label: I18n.homeStatsSortByTime.tr,
        ),
    ];
    final resolvedValue = options.any((option) => option.value == value)
        ? value
        : ScriptStatisticsChartSortField.data;
    return _StatisticsPopupSelector<ScriptStatisticsChartSortField>(
      options: options,
      value: resolvedValue,
      onChanged: onChanged,
    );
  }
}

class _StatisticsMenuOption<T> {
  const _StatisticsMenuOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _StatisticsPopupSelector<T> extends StatelessWidget {
  const _StatisticsPopupSelector({
    required this.options,
    required this.value,
    required this.onChanged,
    this.minWidth = 0,
  });

  final List<_StatisticsMenuOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedOption =
        options.where((option) => option.value == value).firstOrNull ??
            options.firstOrNull;
    if (resolvedOption == null) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_kStatisticsDropdownBorderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(_kStatisticsDropdownBorderRadius),
          onTap: () => _showMenu(context, resolvedOption),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                _kStatisticsDropdownBorderRadius,
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kStatisticsDropdownHorizontalPadding,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      resolvedOption.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down_rounded, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the anchored popup menu for the current selector.
  Future<void> _showMenu(
    BuildContext context,
    _StatisticsMenuOption<T> resolvedOption,
  ) async {
    final position = _resolveMenuPosition(context);
    if (position == null) {
      return;
    }
    final selectedValue = await showMenu<T>(
      context: context,
      position: position,
      initialValue: resolvedOption.value,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kStatisticsDropdownBorderRadius),
      ),
      constraints: const BoxConstraints(
        maxHeight:
            _kStatisticsDateMenuMaxVisibleItems * kMinInteractiveDimension,
      ),
      items: options.map((option) {
        return PopupMenuItem<T>(
          value: option.value,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (option.value == resolvedOption.value) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        );
      }).toList(growable: false),
    );
    if (selectedValue != null && selectedValue != resolvedOption.value) {
      onChanged(selectedValue);
    }
  }

  /// Resolves the popup menu anchor from the selector render box.
  RelativeRect? _resolveMenuPosition(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) {
      return null;
    }
    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = renderBox.localToGlobal(
      renderBox.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    return RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlay.size,
    );
  }
}

class _HistoryDateDropdown extends StatelessWidget {
  const _HistoryDateDropdown({
    required this.values,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = values
        .map(
          (dateKey) => _StatisticsMenuOption(
            value: dateKey,
            label: formatStatisticsDayLabel(dateKey),
          ),
        )
        .toList(growable: false);
    return _StatisticsPopupSelector<String>(
      options: options,
      value: selectedValue,
      onChanged: onChanged,
      minWidth: _kStatisticsDateDropdownMinWidth,
    );
  }
}

class _StatisticsPlaceholder extends StatelessWidget {
  const _StatisticsPlaceholder({
    required this.label,
    this.message = '',
    this.loading = false,
  });

  final String label;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
