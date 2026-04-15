import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/modules/home/updater_view.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';

class AutoScriptButton extends StatelessWidget {
  const AutoScriptButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Get.defaultDialog(
          title: I18n.autoRunScriptList.tr,
          content: const SingleChildScrollView(
            child: AutoScriptDialogContent(),
          ).constrained(maxHeight: 250).card(),
        );
      },
      icon: const Icon(Icons.settings_rounded),
    );
  }
}

void updater() {
  final screenWidth = Get.width;
  final screenHeight = Get.height;
  final proportionalWidth = screenWidth * 0.8;
  final proportionalHeight = screenHeight * 0.7;
  const contentIdealMaxWidth = 700.0;
  final finalMaxWidth = min(contentIdealMaxWidth, proportionalWidth);
  final finalMaxHeight = proportionalHeight;

  Get.defaultDialog(
    title: I18n.updater.tr,
    content: const UpdaterView()
        .constrained(maxWidth: finalMaxWidth, maxHeight: finalMaxHeight),
  );
}

void killServer() {
  final settingsController = Get.find<SettingsController>();
  final isKilling = false.obs;

  Get.dialog(
    Obx(() {
      final killing = isKilling.value;
      return AlertDialog(
        title: Text(I18n.areYouSureKill.tr),
        actions: [
          TextButton(
            onPressed: killing
                ? null
                : () {
                    if (Get.isDialogOpen ?? false) {
                      Get.back();
                    }
                  },
            child: Text(I18n.cancel.tr),
          ),
          FilledButton(
            onPressed: killing
                ? null
                : () async {
                    isKilling.value = true;
                    var closedByTimeout = false;
                    final autoCloseTimer =
                        Timer(const Duration(seconds: 5), () {
                      closedByTimeout = true;
                      if (Get.isDialogOpen ?? false) {
                        Get.back();
                      }
                    });
                    try {
                      final success = await settingsController.killServer();
                      if (success) {
                        if (!closedByTimeout && (Get.isDialogOpen ?? false)) {
                          Get.back();
                        }
                        return;
                      }
                      if (!closedByTimeout) {
                        isKilling.value = false;
                      }
                    } finally {
                      autoCloseTimer.cancel();
                    }
                  },
            child: killing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(I18n.confirm.tr),
          ),
        ],
      );
    }),
    barrierDismissible: false,
  );
}

class AutoScriptDialogContent extends StatelessWidget {
  const AutoScriptDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final scriptService = Get.find<ScriptService>();
    final scriptList = scriptService.scriptModelMap.keys.toList()..sort();
    return scriptList
        .map((item) {
          return Obx(() {
            return <Widget>[
              Expanded(
                child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Checkbox(
                value: scriptService.autoScriptList.contains(item),
                onChanged: (nv) => scriptService.updateAutoScript(item, nv),
              ),
            ]
                .toRow(mainAxisAlignment: MainAxisAlignment.spaceBetween)
                .paddingSymmetric(vertical: 4, horizontal: 8);
          });
        })
        .toList()
        .toColumn(mainAxisSize: MainAxisSize.min);
  }
}
