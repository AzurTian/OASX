import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/script_statistics_models.dart';
import 'package:oasx/modules/home/widgets/statistics_formatters.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Task comparison chart with a fixed top axis.
class ScriptStatisticsHistoryChart extends StatelessWidget {
  /// Creates a task comparison chart.
  const ScriptStatisticsHistoryChart({
    super.key,
    required this.entries,
    required this.metric,
    required this.focusedTaskName,
    required this.onSelectTask,
    required this.flashingTaskName,
    required this.flashToken,
    required this.highlightRealtimeTask,
  });

  /// Task aggregates sorted by the selected metric.
  final List<MapEntry<String, ScriptTaskStatistics>> entries;

  /// Metric currently shown by the chart.
  final ScriptStatisticsChartMetric metric;

  /// Currently focused task name.
  final String focusedTaskName;

  /// Called when the user taps a task bar.
  final ValueChanged<String> onSelectTask;

  /// Task currently highlighted by a realtime update.
  final String flashingTaskName;

  /// Token used to restart the flash animation.
  final int flashToken;

  /// Whether realtime task highlighting is active.
  final bool highlightRealtimeTask;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxValue = entries.fold<double>(
      0,
      (current, entry) =>
          math.max(current, entry.value.metricValueFor(metric)).toDouble(),
    );
    final interval = _resolveInterval(maxValue);
    final axisMax = _resolveAxisMax(maxValue, interval);
    final ticks = _buildTicks(axisMax, interval);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryAxisHeader(
          ticks: ticks,
          axisMax: axisMax,
          metric: metric,
        ),
        const SizedBox(height: 8),
        ...List.generate(entries.length, (index) {
          final entry = entries[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : 10),
            child: _HistoryBarRow(
              entry: entry,
              metric: metric,
              axisMax: axisMax,
              focused: entry.key == focusedTaskName,
              flashing: highlightRealtimeTask && flashingTaskName == entry.key,
              flashToken: flashToken,
              onTap: () => onSelectTask(entry.key),
            ),
          );
        }),
      ],
    );
  }

  /// Builds fixed axis ticks using the resolved interval.
  List<double> _buildTicks(double axisMax, double interval) {
    final ticks = <double>[0];
    var cursor = interval;
    while (cursor <= axisMax) {
      ticks.add(cursor);
      cursor += interval;
    }
    return ticks;
  }

  /// Resolves the chart max to the next interval step.
  double _resolveAxisMax(double maxValue, double interval) {
    if (interval <= 0) {
      return 1.0;
    }
    return math.max(interval, (maxValue / interval).ceil() * interval).toDouble();
  }

  /// Resolves a stable axis interval for the current metric family.
  double _resolveInterval(double maxValue) {
    if (statisticsMetricUsesDuration(metric)) {
      if (maxValue <= 600) {
        return 120.0;
      }
      if (maxValue <= 3600) {
        return 600.0;
      }
      if (maxValue <= 4 * 3600) {
        return 1800.0;
      }
      return 3600.0;
    }
    if (maxValue <= 10) {
      return 2.0;
    }
    if (maxValue <= 50) {
      return 10.0;
    }
    if (maxValue <= 100) {
      return 20.0;
    }
    return math.max((maxValue / 5).ceilToDouble(), 1.0).toDouble();
  }
}

class _HistoryAxisHeader extends StatelessWidget {
  const _HistoryAxisHeader({
    required this.ticks,
    required this.axisMax,
    required this.metric,
  });

  final List<double> ticks;
  final double axisMax;
  final ScriptStatisticsChartMetric metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 116),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    ...ticks.map((tick) {
                      final ratio = axisMax <= 0 ? 0.0 : tick / axisMax;
                      final left =
                          math.min(math.max(ratio * width, 0.0), width).toDouble();
                      final resolvedLeft = math
                          .min(
                            math.max(left - 24.0, 0.0),
                            math.max(width - 48.0, 0.0),
                          )
                          .toDouble();
                      return Positioned(
                        left: resolvedLeft,
                        child: SizedBox(
                          width: 48,
                          child: Text(
                            formatStatisticsMetricByType(tick, metric),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryBarRow extends StatelessWidget {
  const _HistoryBarRow({
    required this.entry,
    required this.metric,
    required this.axisMax,
    required this.focused,
    required this.flashing,
    required this.flashToken,
    required this.onTap,
  });

  final MapEntry<String, ScriptTaskStatistics> entry;
  final ScriptStatisticsChartMetric metric;
  final double axisMax;
  final bool focused;
  final bool flashing;
  final int flashToken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = statisticsTaskColor(entry.key);
    final value = entry.value.metricValueFor(metric);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            entry.key.tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: focused ? color : null,
                  fontWeight: focused ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ratio = axisMax <= 0 ? 0.0 : value / axisMax;
              final barWidth = math.max(constraints.maxWidth * ratio, 8.0).toDouble();
              final scheme = Theme.of(context).colorScheme;
              return Tooltip(
                preferBelow: false,
                verticalOffset: 20,
                message: _tooltipText(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: barWidth,
                          height: focused ? 28 : 24,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: focused ? 0.92 : 0.76),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: focused ? scheme.onSurface : color,
                              width: focused ? 1.3 : 1,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: _HistoryValueBadge(
                            label: formatStatisticsMetricByType(value, metric),
                            color: color,
                            flashing: flashing,
                            flashToken: flashToken,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds tooltip lines without repeating the task name.
  String _tooltipText() {
    return '${I18n.homeStatsTotalDuration.tr}: '
        '${formatStatisticsDuration(entry.value.totalDurationSeconds)}\n'
        '${I18n.homeStatsRunCount.tr}: ${entry.value.runCount}\n'
        '${I18n.homeStatsBattleCount.tr}: ${entry.value.battleCount}\n'
        '${I18n.homeStatsBattleAvgDuration.tr}: '
        '${formatStatisticsDuration(entry.value.battleAvgDurationSeconds)}\n'
        '${I18n.homeStatsAvgRunDuration.tr}: '
        '${formatStatisticsDuration(entry.value.avgRunDurationSeconds)}';
  }
}

class _HistoryValueBadge extends StatelessWidget {
  const _HistoryValueBadge({
    required this.label,
    required this.color,
    required this.flashing,
    required this.flashToken,
  });

  final String label;
  final Color color;
  final bool flashing;
  final int flashToken;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      key: ValueKey('$label|$flashToken|$flashing'),
      tween: Tween<double>(begin: flashing ? 1 : 0, end: 0),
      duration: Duration(milliseconds: flashing ? 1300 : 180),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final pulse = flashing ? value : 0.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.transparent,
              color.withValues(alpha: 0.18),
              pulse,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Color.lerp(
                    Colors.transparent,
                    color.withValues(alpha: 0.56),
                    pulse,
                  ) ??
                  Colors.transparent,
            ),
            boxShadow: pulse > 0
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.26 * pulse),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: pulse > 0.02 ? scheme.onSurface : null,
                  ),
            ),
          ),
        );
      },
    );
  }
}

