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
    required this.onOpenLog,
    required this.onScriptMenuSelected,
  });

  final List<ScriptModel> scripts;
  final ScriptService scriptService;
  final ValueChanged<String> onOpenLog;
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
        final totalCount = widget.scripts.length;
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
    if (index >= widget.scripts.length) {
      return const SizedBox.shrink();
    }
    final script = widget.scripts[index];
    return HomeScriptCard(
      scriptModel: script,
      scriptService: widget.scriptService,
      onOpenLog: () => widget.onOpenLog(script.name),
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
