import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/home/widgets/home_script_card.dart';

class HomeScriptActions {
  const HomeScriptActions._();

  static Future<void> onMenuSelected({
    required HomeScriptMenuAction action,
    required String scriptName,
    required ScriptService scriptService,
  }) async {
    switch (action) {
      case HomeScriptMenuAction.rename:
        await _showRenameDialog(scriptService, scriptName);
        break;
      case HomeScriptMenuAction.delete:
        await _showDeleteDialog(scriptService, scriptName);
        break;
    }
  }

  static Future<void> _showRenameDialog(
      ScriptService scriptService, String oldName) async {
    final canRename = await scriptService.tryCloseScriptWithReason(oldName);
    if (!canRename) return;

    var newName = oldName;
    final formKey = GlobalKey<FormState>();
    Get.defaultDialog(
      title: I18n.rename.tr,
      textConfirm: I18n.confirm.tr,
      textCancel: I18n.cancel.tr,
      content: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: TextFormField(
          decoration: InputDecoration(
            labelText: I18n.new_name.tr,
          ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return I18n.name_cannot_empty.tr;
            }
            if (['Home', 'home'].contains(value)) {
              return I18n.name_invalid.tr;
            }
            if (oldName == value ||
                scriptService.scriptOrderList.contains(value)) {
              return I18n.name_duplicate.tr;
            }
            return null;
          },
          onChanged: (v) => newName = v.trim(),
        ),
      ),
      onConfirm: () async {
        if (!(formKey.currentState?.validate() ?? false)) {
          return;
        }
        Get.back();
        final success = await scriptService.renameConfig(oldName, newName);
        if (!success) {
          Get.snackbar(I18n.error.tr, '');
        }
      },
      onCancel: () {},
    );
  }

  static Future<void> _showDeleteDialog(
      ScriptService scriptService, String name) async {
    final canDelete = await scriptService.tryCloseScriptWithReason(name);
    if (!canDelete) return;

    Get.defaultDialog(
      title: I18n.delete.tr,
      textConfirm: I18n.confirm.tr,
      textCancel: I18n.cancel.tr,
      middleText: '${I18n.delete_confirm.tr} "$name"?',
      onConfirm: () async {
        Get.back();
        final success = await scriptService.deleteConfig(name);
        if (!success) {
          Get.snackbar(I18n.error.tr, '');
        }
      },
      onCancel: () {},
    );
  }
}
