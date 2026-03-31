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
const _kStatisticsRuntimeCardMinWidth = 194.0;
const _kStatisticsCountCardMinWidth = 108.0;

/// Main statistics tab content for the active script.
class ScriptStatisticsPanel extends StatelessWidget {
  /// Creates the statistics panel.
  const ScriptStatisticsPanel({super.key});

  /// Controller that owns statistics state.
  HomeStatisticsController get controller => Get.find<HomeStatisticsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final statistics = controller.statistics.value;
      final availableDates = controller.availableDateKeys.toList(growable: false);
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
        controller.connectionState.value != ScriptStatisticsConnectionState.error &&
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
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderTopRow(
            availableDateKeys: availableDateKeys,
            controller: controller,
          ),
          const SizedBox(height: _kStatisticsPanelSectionSpacing),
          _SummaryCards(day: statistics),
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
    required this.availableDateKeys,
    required this.controller,
  });

  final List<String> availableDateKeys;
  final HomeStatisticsController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: _kStatisticsSummarySpacing,
      runSpacing: _kStatisticsSummarySpacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatusIcon(controller: controller),
        _HistoryDateDropdown(
          values: availableDateKeys,
          selectedValue: controller.selectedDateKey.value,
          onChanged: controller.selectHistoryDate,
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
      return controller.lastErrorMessage.value.isEmpty ? '' : I18n.homeStatsStreamError.tr;
    }
    return switch (controller.connectionState.value) {
      ScriptStatisticsConnectionState.connecting => '',
      ScriptStatisticsConnectionState.connected => '',
      ScriptStatisticsConnectionState.reconnecting => I18n.homeStatsReconnecting.tr,
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
        controller.connectionState.value == ScriptStatisticsConnectionState.error) {
      return scheme.error;
    }
    if (controller.isTodaySelected &&
        controller.connectionState.value == ScriptStatisticsConnectionState.connected) {
      return Colors.teal;
    }
    return scheme.primary;
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.day});

  final ScriptStatisticsDay day;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: _kStatisticsSummarySpacing,
      runSpacing: _kStatisticsSummarySpacing,
      children: [
        SizedBox(
          width: _kStatisticsRuntimeCardMinWidth,
          child: _SummaryCard(
            data: _SummaryCardData(
              label: I18n.homeStatsSummaryRunDuration.tr,
              value: formatStatisticsDuration(day.totalRuntimeSeconds),
            ),
          ),
        ),
        SizedBox(
          width: _kStatisticsCountCardMinWidth,
          child: _SummaryCard(
            data: _SummaryCardData(
              label: I18n.homeStatsSummaryRunTaskCount.tr,
              value: day.taskCount.toString(),
            ),
          ),
        ),
        SizedBox(
          width: _kStatisticsCountCardMinWidth,
          child: _SummaryCard(
            data: _SummaryCardData(
              label: I18n.homeStatsSummaryTotalBattleCount.tr,
              value: day.totalBattleCount.toString(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({required this.label, required this.value});

  final String label;
  final String value;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.brightness == Brightness.dark
          ? scheme.surfaceContainerHigh
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.brightness == Brightness.dark
              ? scheme.outlineVariant.withValues(alpha: 0.9)
              : scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.label,
              style: Theme.of(context).textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              data.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ScriptStatisticsChartMetric>(
            value: value,
            onChanged: (next) {
              if (next != null) {
                onChanged(next);
              }
            },
            items: ScriptStatisticsChartMetric.values.map((metric) {
              return DropdownMenuItem(
                value: metric,
                child: Text(_labelForMetric(metric)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Resolves the dropdown label for one metric.
  String _labelForMetric(ScriptStatisticsChartMetric metric) {
    return switch (metric) {
      ScriptStatisticsChartMetric.totalDuration => I18n.homeStatsTotalDuration.tr,
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
    final items = <DropdownMenuItem<ScriptStatisticsChartSortField>>[
      DropdownMenuItem(
        value: ScriptStatisticsChartSortField.data,
        child: Text(I18n.homeStatsSortByData.tr),
      ),
      if (allowTime)
        DropdownMenuItem(
          value: ScriptStatisticsChartSortField.time,
          child: Text(I18n.homeStatsSortByTime.tr),
        ),
    ];
    final resolvedValue = items.any((item) => item.value == value)
        ? value
        : ScriptStatisticsChartSortField.data;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ScriptStatisticsChartSortField>(
            value: resolvedValue,
            onChanged: (next) {
              if (next != null) {
                onChanged(next);
              }
            },
            items: items,
          ),
        ),
      ),
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
    final resolvedValue = values.contains(selectedValue) && selectedValue.isNotEmpty
        ? selectedValue
        : values.firstOrNull;
    if (resolvedValue == null) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: resolvedValue,
            menuMaxHeight: kMinInteractiveDimension * 6,
            onChanged: (next) {
              if (next != null) {
                onChanged(next);
              }
            },
            items: values.map((dateKey) {
              return DropdownMenuItem(
                value: dateKey,
                child: Text(formatStatisticsDayLabel(dateKey)),
              );
            }).toList(),
          ),
        ),
      ),
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
