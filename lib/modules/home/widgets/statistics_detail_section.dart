import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/script_statistics_models.dart';
import 'package:oasx/modules/home/widgets/statistics_formatters.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Task execution detail list rendered below the chart.
class ScriptStatisticsDetailSection extends StatelessWidget {
  /// Creates a task execution detail section.
  const ScriptStatisticsDetailSection({
    super.key,
    required this.taskName,
    required this.runs,
  });

  /// Task name currently focused by the chart.
  final String taskName;

  /// Visible run records for the focused task.
  final List<ScriptTaskRunRecord> runs;

  @override
  Widget build(BuildContext context) {
    if (taskName.trim().isEmpty) {
      return _DetailPlaceholder(
        label: I18n.homeStatsNoTaskSelected.tr,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${I18n.homeStatsRunDetails.tr}: ${taskName.tr}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (runs.isEmpty)
          _DetailPlaceholder(label: I18n.homeStatsTaskDetailEmpty.tr)
        else
          ...List.generate(runs.length, (index) {
            final displayIndex = runs.length - index;
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == runs.length - 1 ? 0 : 8),
              child: _RunCard(
                taskName: taskName,
                run: runs[index],
                serialNumber: displayIndex,
              ),
            );
          }),
      ],
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard({
    required this.taskName,
    required this.run,
    required this.serialNumber,
  });

  final String taskName;
  final ScriptTaskRunRecord run;
  final int serialNumber;

  @override
  Widget build(BuildContext context) {
    final color = statisticsTaskColor(taskName);
    final scheme = Theme.of(context).colorScheme;
    final hasBattle = run.battleCount > 0;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$serialNumber',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatStatisticsClockTimeRange(run.startTime, run.endTime),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasBattle
                        ? '${I18n.homeStatsBattleCount.tr}: ${run.battleCount}  ·  '
                            '${I18n.homeStatsBattleAvgDuration.tr}: '
                            '${formatStatisticsDuration(run.battleAvgDurationSeconds)}'
                        : I18n.homeStatsNoBattle.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatStatisticsDuration(run.durationSeconds),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
