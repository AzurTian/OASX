import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/views/home/widgets/home_constants.dart';
import 'package:oasx/views/home/widgets/home_script_card.dart';

class HomeScriptGrid extends StatefulWidget {
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
  State<HomeScriptGrid> createState() => _HomeScriptGridState();
}

class _HomeScriptGridState extends State<HomeScriptGrid> {
  final Map<int, bool> _expandedRows = {};
  int _lastCrossAxisCount = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minCardWidth = 340.0;
        final crossAxisCount =
            max(1, (constraints.maxWidth / minCardWidth).floor());
        if (_lastCrossAxisCount != crossAxisCount) {
          _expandedRows.clear();
          _lastCrossAxisCount = crossAxisCount;
        }
        final totalCount = widget.scripts.length + 1;
        final rowCount = (totalCount / crossAxisCount).ceil();

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: rowCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, rowIndex) {
            final expanded = _expandedRows[rowIndex] ?? false;
            final taskListHeight = expanded
                ? kHomeTaskListExpandedHeight
                : kHomeTaskListCollapsedHeight;
            final cardHeight = homeScriptCardHeight(taskListHeight);

            return SizedBox(
              height: cardHeight,
              child: Row(
                children: List.generate(crossAxisCount, (columnIndex) {
                  final index = rowIndex * crossAxisCount + columnIndex;
                  final child = _buildItem(
                    index: index,
                    rowIndex: rowIndex,
                    taskListHeight: taskListHeight,
                  );
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: columnIndex == crossAxisCount - 1 ? 0 : 12,
                      ),
                      child: child,
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItem({
    required int index,
    required int rowIndex,
    required double taskListHeight,
  }) {
    if (index > widget.scripts.length) {
      return const SizedBox.shrink();
    }
    if (index == widget.scripts.length) {
      return _AddScriptCard(
        loading: widget.loadingAddScript,
        onTap: widget.onAddScriptTap,
      );
    }
    final script = widget.scripts[index];
    return HomeScriptCard(
      scriptModel: script,
      scriptService: widget.scriptService,
      onOpenOverview: () => widget.onOpenOverview(script.name),
      onMenuSelected: (action) =>
          widget.onScriptMenuSelected(action, script.name),
      taskListHeight: taskListHeight,
      onTaskListTap: () => _toggleRow(rowIndex),
    );
  }

  void _toggleRow(int rowIndex) {
    setState(() {
      _expandedRows[rowIndex] = !(_expandedRows[rowIndex] ?? false);
    });
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
    return Card(
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
    );
  }
}
