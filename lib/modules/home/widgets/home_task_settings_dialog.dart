import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/translation/i18n_content.dart';

class HomeTaskSettingsDialog {
  const HomeTaskSettingsDialog._();

  static void show({
    required String scriptName,
    required String taskName,
    SaveArgumentCallback? saveArgumentOverride,
    List<String> scopeScripts = const [],
  }) {
    final maxWidth = min(750.0, Get.width * 0.9);
    final maxHeight = Get.height * 0.7;
    final argsController = Get.find<ArgsController>();
    final saveScope = scopeScripts.isEmpty ? <String>[scriptName] : scopeScripts;
    Get.defaultDialog(
      title: '${taskName.tr}${I18n.setting.tr}',
      content: FutureBuilder<void>(
        future: argsController.loadGroups(
          config: scriptName,
          task: taskName,
          stagingMode: true,
          scopeScripts: saveScope,
          saveArgumentOverride: saveArgumentOverride,
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
              stagingMode: true,
            ),
          );
        },
      ),
    );
  }
}
