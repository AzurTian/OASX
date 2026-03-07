library args;

import 'dart:async';
import 'dart:convert';

import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/modules/overview/index.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../translation/i18n_content.dart';

part 'widgets/group_view.dart';
part 'widgets/date_time_picker.dart';
part 'widgets/time_delta_picker.dart';
part 'widgets/time_picker.dart';
part 'widgets/argument_view.dart';
part 'widgets/argument_view_actions.dart';
part 'controllers/args_controller.dart';

typedef SetArgumentCallback = void Function(
  String? config,
  String? task,
  String group,
  String argument,
  String type,
  dynamic value,
);

class Args extends StatelessWidget {
  const Args({
    Key? key,
    this.scriptName,
    this.taskName,
    this.groupDraggable = true,
    this.setArgumentOverride,
  }) : super(key: key);

  final String? scriptName;
  final String? taskName;
  final bool groupDraggable;
  final SetArgumentCallback? setArgumentOverride;

  @override
  Widget build(BuildContext context) {
    return GetX<ArgsController>(builder: (controller) {
      final selectedScript = (scriptName ?? Get.parameters['script'] ?? '').trim();
      final selectedTask = (taskName ?? Get.parameters['task'] ?? '').trim();
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: ExpansionTileGroup(
          spaceBetweenItem: 10,
          children: controller.groupsName.value
              .map(
                (name) => ExpansionTileItem(
                  initiallyExpanded: true,
                  isHasTopBorder: false,
                  isHasBottomBorder: false,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.24),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  title: <Widget>[
                    if (groupDraggable)
                      Draggable<Map<String, dynamic>>(
                        data: {
                          'model': TaskItemModel(
                            scriptName ?? selectedScript,
                            taskName ?? selectedTask,
                            '',
                            groupName: name,
                          ),
                          'source': 'argsViewGroup',
                        },
                        feedback: _buildFeedback(context, name),
                        child: const Icon(Icons.drag_indicator_outlined),
                      ),
                    Text(name.tr),
                  ].toRow(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                  ),
                  children: _children(name),
                ),
              )
              .toList(),
        ).constrained(maxWidth: 700, minWidth: 100),
      ).alignment(Alignment.topCenter);
    });
  }

  List<Widget> _children(String groupName) {
    final controller = Get.find<ArgsController>();
    final setArgument = setArgumentOverride ?? controller.setArgument;
    final groupsModel = controller.groupsData.value[groupName]!;
    final result = <Widget>[const Divider()];
    for (int i = 0; i < groupsModel.members.length; i++) {
      result.add(
        ArgumentView(
          scriptName: scriptName,
          taskName: taskName,
          setArgument: setArgument,
          getGroupName: groupsModel.getGroupName,
          index: i,
        ),
      );
    }
    return result;
  }

  Widget _buildFeedback(BuildContext context, String title) {
    final themeService = Get.find<ThemeService>();
    return Material(
      color: Colors.transparent,
      child: Text(title.tr, style: Theme.of(context).textTheme.titleMedium)
          .decorated(
            color: themeService.isDarkMode
                ? Colors.blueGrey.shade700
                : Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          )
          .width(150)
          .height(30)
          .paddingAll(8)
          .opacity(0.8),
    );
  }
}




