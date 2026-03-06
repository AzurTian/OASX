import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';

class HomeOverviewHeader extends StatelessWidget {
  const HomeOverviewHeader({
    super.key,
    required this.scriptService,
  });

  final ScriptService scriptService;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Obx(() {
            final scripts = scriptService.scriptOrderList
                .map((name) => scriptService.scriptModelMap[name])
                .whereType<ScriptModel>()
                .toList();
            final runningCount = scripts
                .where((e) => e.state.value == ScriptState.running)
                .length;
            final totalCount = scripts.length;

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18n.home_overview_control.tr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: compact ? 12 : 24,
                      runSpacing: 12,
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
                    ),
                  ],
                );
              },
            );
          }),
        ),
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
