library args;

import 'dart:async';
import 'dart:convert';

import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/overview/index.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/websocket_service.dart';
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

typedef SaveArgumentCallback = Future<bool> Function(
  String config,
  String task,
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
    this.stagingMode = false,
    this.setArgumentOverride,
    this.onCancel,
  }) : super(key: key);

  final String? scriptName;
  final String? taskName;
  final bool groupDraggable;
  final bool stagingMode;
  final SetArgumentCallback? setArgumentOverride;
  final Future<void> Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    return GetX<ArgsController>(builder: (controller) {
      final selectedScript = (scriptName ?? Get.parameters['script'] ?? '').trim();
      final selectedTask = (taskName ?? Get.parameters['task'] ?? '').trim();
      final groupNames = controller.groupsName.value;
      final content = LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: ExpansionTileGroup(
                spaceBetweenItem: 10,
                children: groupNames
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
              ),
            ),
          );
        },
      );
      if (!stagingMode) {
        return content;
      }
      return Column(
        children: [
          Expanded(child: content),
          ArgsDraftBar(
            scriptName: selectedScript,
            taskName: selectedTask,
            onCancel: onCancel,
          ),
        ],
      );
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

class ArgsDraftBar extends StatelessWidget {
  const ArgsDraftBar({
    super.key,
    required this.scriptName,
    required this.taskName,
    this.onCancel,
  });

  final String scriptName;
  final String taskName;
  final Future<void> Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = Get.find<ArgsController>();
      final dirtyCount = controller.dirtyFieldKeys.length;
      final scopeCount = controller.scopeScriptCount.value;
      final pendingCount = dirtyCount * scopeCount;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${I18n.argsDraftDirty.tr}: $pendingCount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            TextButton(
              onPressed: () async {
                await controller.discardDraftChanges();
                await onCancel?.call();
              },
              child: Text(I18n.cancel.tr),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: controller.isSavingDraft.value || dirtyCount == 0
                  ? null
                  : () async {
                      final ret = await controller.saveDraftChanges();
                      if (ret) {
                        Get.snackbar(
                          I18n.settingSaved.tr,
                          '$scriptName / $taskName',
                        );
                        return;
                      }
                      Get.snackbar(
                        I18n.error.tr,
                        I18n.argsValidationFailed.tr,
                      );
                    },
              icon: controller.isSavingDraft.value
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(I18n.argsSaveChanges.tr),
            ),
          ],
        ).paddingAll(12),
      );
    });
  }
}










