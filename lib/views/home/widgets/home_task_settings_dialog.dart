import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/args/args_view.dart';

class HomeTaskSettingsDialog {
  const HomeTaskSettingsDialog._();

  static void show({
    required String scriptName,
    required String taskName,
    SetArgumentCallback? setArgumentOverride,
  }) {
    final maxWidth = min(750.0, Get.width * 0.9);
    final maxHeight = Get.height * 0.7;
    final argsController = Get.find<ArgsController>();
    final setArgument = setArgumentOverride ?? argsController.setArgument;
    Get.defaultDialog(
      title: '${taskName.tr}${I18n.setting.tr}',
      content: FutureBuilder<void>(
        future: argsController.loadGroups(
          config: scriptName,
          task: taskName,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('${I18n.error.tr}: ${snapshot.error}');
          }
          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: maxWidth,
              minHeight: maxHeight,
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: Args(
              scriptName: scriptName,
              taskName: taskName,
              groupDraggable: false,
              setArgumentOverride: setArgument,
            ),
          );
        },
      ),
    );
  }
}
