import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/models/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';

class HomeOverviewHeader extends StatelessWidget {
  const HomeOverviewHeader({
    super.key,
    required this.scriptService,
    required this.loadingAddScript,
    required this.refreshingScripts,
    required this.onAddScriptTap,
    required this.onRefreshScriptsTap,
    required this.isLinkModeEnabled,
    required this.onToggleLinkMode,
  });

  final ScriptService scriptService;
  final bool loadingAddScript;
  final bool refreshingScripts;
  final VoidCallback onAddScriptTap;
  final VoidCallback onRefreshScriptsTap;
  final bool isLinkModeEnabled;
  final VoidCallback onToggleLinkMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Obx(() {
          final scripts = scriptService.scriptOrderList
              .map((name) => scriptService.scriptModelMap[name])
              .whereType<ScriptModel>()
              .toList();
          final runningCount =
              scripts.where((e) => e.state.value == ScriptState.running).length;
          final totalCount = scripts.length;

          return LayoutBuilder(
            builder: (context, constraints) {
              const metricsSpacing = 14.0;
              const sectionSpacing = 12.0;
              const sideLayoutReserve = 120.0;
              const actionsMinWidth = 96.0;
              const metricMinWidth = 140.0;
              const metricCount = 2;
              const minSingleRowWidth =
                  metricMinWidth * metricCount + metricsSpacing;
              final useSideLayout = constraints.maxWidth >=
                  minSingleRowWidth +
                      sectionSpacing +
                      actionsMinWidth +
                      sideLayoutReserve;

              Wrap buildMetrics({required bool centered}) {
                return Wrap(
                  alignment:
                      centered ? WrapAlignment.center : WrapAlignment.start,
                  runAlignment:
                      centered ? WrapAlignment.center : WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: metricsSpacing,
                  runSpacing: 10,
                  children: [
                    _CountMetric(
                      label: I18n.run.tr,
                      value: '$runningCount',
                      color: Colors.green,
                    ),
                    _CountMetric(
                      label: I18n.homeTotalScripts.tr,
                      value: '$totalCount',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                );
              }

              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: I18n.homeConnectionRetryAction.tr,
                    onPressed: refreshingScripts ? null : onRefreshScriptsTap,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                    icon: refreshingScripts
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: isLinkModeEnabled
                        ? I18n.closeTheLinker.tr
                        : I18n.turnOnTheLinker.tr,
                    onPressed: onToggleLinkMode,
                    style: IconButton.styleFrom(
                      backgroundColor: isLinkModeEnabled
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      foregroundColor: isLinkModeEnabled
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.link_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: I18n.configAdd.tr,
                    onPressed: loadingAddScript ? null : onAddScriptTap,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                    icon: loadingAddScript
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded),
                  ),
                ],
              );

              if (useSideLayout) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: buildMetrics(centered: false)),
                    const SizedBox(width: sectionSpacing),
                    actions,
                  ],
                );
              }

              return Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: sectionSpacing,
                runSpacing: 10,
                children: [
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: constraints.maxWidth),
                    child: buildMetrics(centered: true),
                  ),
                  actions,
                ],
              );
            },
          );
        }),
      ),
    );
  }
}

class _CountMetric extends StatelessWidget {
  const _CountMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}
