import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oasx/modules/home/models/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/modules/home/widgets/home_constants.dart';
import 'package:oasx/modules/home/widgets/home_script_card.dart';
import 'package:oasx/modules/home/widgets/home_task_summary.dart';

class HomeScriptGrid extends StatefulWidget {
  const HomeScriptGrid({
    super.key,
    required this.scripts,
    required this.scriptService,
    required this.onOpenLog,
    required this.isLinkModeEnabled,
    required this.linkedScripts,
    required this.onLinkedChanged,
    required this.onToggleScriptPower,
    required this.onSetTaskArgument,
    required this.onOpenTaskSettings,
    this.bottomReservedSpace = 0,
  });

  final List<ScriptModel> scripts;
  final ScriptService scriptService;
  final ValueChanged<String> onOpenLog;
  final bool isLinkModeEnabled;
  final List<String> linkedScripts;
  final void Function(String scriptName, bool linked) onLinkedChanged;
  final Future<void> Function(String scriptName, bool enable)
      onToggleScriptPower;
  final HomeTaskArgumentSetter onSetTaskArgument;
  final void Function(String scriptName, String taskName) onOpenTaskSettings;
  final double bottomReservedSpace;

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
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            12 + widget.bottomReservedSpace,
          ),
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
      taskListHeight: taskListHeight,
      onTaskListTap: () => _toggleRow(rowIndex),
      showLinkCheckbox: widget.isLinkModeEnabled,
      isLinked: widget.linkedScripts.contains(script.name),
      onLinkedChanged: (linked) => widget.onLinkedChanged(script.name, linked),
      onTogglePower: (enable) => widget.onToggleScriptPower(script.name, enable),
      onSetTaskArgument: widget.onSetTaskArgument,
      onOpenTaskSettings: widget.onOpenTaskSettings,
    );
  }

  void _toggleRow(int rowIndex) {
    setState(() {
      _expandedRows[rowIndex] = !(_expandedRows[rowIndex] ?? false);
    });
  }
}

