import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/views/home/widgets/home_constants.dart';
import 'package:oasx/views/home/widgets/home_script_card.dart';

class HomeScriptGrid extends StatelessWidget {
  const HomeScriptGrid({
    super.key,
    required this.scripts,
    required this.scriptService,
    required this.loadingAddScript,
    required this.onAddScriptTap,
    required this.onOpenOverview,
    required this.onScriptMenuSelected,
  });

  final List<ScriptModel> scripts;
  final ScriptService scriptService;
  final bool loadingAddScript;
  final VoidCallback onAddScriptTap;
  final ValueChanged<String> onOpenOverview;
  final void Function(HomeScriptMenuAction action, String scriptName)
      onScriptMenuSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minCardWidth = 340.0;
        final crossAxisCount =
            max(1, (constraints.maxWidth / minCardWidth).floor());
        final totalCount = scripts.length + 1;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: totalCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: kHomeScriptCardHeight,
          ),
          itemBuilder: (context, index) {
            if (index == scripts.length) {
              return _AddScriptCard(
                loading: loadingAddScript,
                onTap: onAddScriptTap,
              );
            }
            final script = scripts[index];
            return HomeScriptCard(
              scriptModel: script,
              scriptService: scriptService,
              onOpenOverview: () => onOpenOverview(script.name),
              onMenuSelected: (action) =>
                  onScriptMenuSelected(action, script.name),
            );
          },
        );
      },
    );
  }
}

class _AddScriptCard extends StatelessWidget {
  const _AddScriptCard({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kHomeScriptCardHeight,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.add_rounded, size: 36),
            ),
          ),
        ),
      ),
    );
  }
}
