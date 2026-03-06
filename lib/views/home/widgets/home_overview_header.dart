import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';

class HomeOverviewHeader extends StatelessWidget {
  const HomeOverviewHeader({
    super.key,
    required this.scriptService,
    required this.loadingAddScript,
    required this.onAddScriptTap,
    required this.isLinkModeEnabled,
    required this.onToggleLinkMode,
  });

  final ScriptService scriptService;
  final bool loadingAddScript;
  final VoidCallback onAddScriptTap;
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
              final compact = constraints.maxWidth < 720;
              final metrics = Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: compact ? 10 : 14,
                runSpacing: 10,
                children: [
                  _CountMetric(
                    label: I18n.running.tr,
                    value: '$runningCount',
                    color: Colors.green,
                  ),
                  _CountMetric(
                    label: I18n.home_total_scripts.tr,
                    value: '$totalCount',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              );

              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: isLinkModeEnabled
                        ? I18n.home_link_mode_disable.tr
                        : I18n.home_link_mode_enable.tr,
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
                  Tooltip(
                    message: I18n.config_add.tr,
                    child: ElevatedButton(
                      onPressed: loadingAddScript ? null : onAddScriptTap,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                      ),
                      child: loadingAddScript
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_rounded, size: 20),
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [actions],
                    ),
                    const SizedBox(height: 10),
                    metrics,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: metrics),
                  const SizedBox(width: 12),
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
