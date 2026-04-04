import 'package:flutter/material.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';

class ConfigStateIndicator extends StatelessWidget {
  const ConfigStateIndicator({
    super.key,
    required this.state,
    this.size = 18,
  });

  final HomeScriptStateFilter state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(state, context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: size + 12,
        height: size + 12,
        child: Icon(
          palette.icon,
          size: size,
          color: palette.color,
        ),
      ),
    );
  }

  _StatePalette _paletteFor(
    HomeScriptStateFilter value,
    BuildContext context,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return switch (value) {
      HomeScriptStateFilter.running => const _StatePalette(
          color: Colors.green,
          icon: Icons.circle_rounded,
        ),
      HomeScriptStateFilter.abnormal => const _StatePalette(
          color: Colors.orange,
          icon: Icons.circle_rounded,
        ),
      HomeScriptStateFilter.stopped => const _StatePalette(
          color: Colors.grey,
          icon: Icons.donut_large,
        ),
      HomeScriptStateFilter.offline => const _StatePalette(
          color: Colors.blue,
          icon: Icons.browser_updated_rounded,
        ),
      HomeScriptStateFilter.all => _StatePalette(
          color: scheme.outline,
          icon: Icons.circle,
        ),
    };
  }
}

class _StatePalette {
  const _StatePalette({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;
}
