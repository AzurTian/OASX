import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigActions {
  const ConfigActions._();

  static String? validateRenameName({
    required String oldName,
    required String newName,
    required ScriptService scriptService,
  }) {
    if (newName.isEmpty) {
      return I18n.nameCannotEmpty.tr;
    }
    if (['Home', 'home'].contains(newName)) {
      return I18n.nameInvalid.tr;
    }
    if (oldName == newName || scriptService.scriptOrderList.contains(newName)) {
      return I18n.nameDuplicate.tr;
    }
    return null;
  }

  static Future<bool> renameScript({
    required ScriptService scriptService,
    required String oldName,
    required String newName,
  }) async {
    final canRename = await scriptService.tryCloseScriptWithReason(oldName);
    if (!canRename) return false;

    final success = await scriptService.renameConfig(oldName, newName);
    if (!success) {
      Get.snackbar(I18n.error.tr, '');
    }
    return success;
  }

  static Future<void> showRenameDialog({
    required ScriptService scriptService,
    required String oldName,
  }) async {
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
            labelText: I18n.newName.tr,
          ),
          validator: (String? value) {
            final input = value?.trim() ?? '';
            return validateRenameName(
              oldName: oldName,
              newName: input,
              scriptService: scriptService,
            );
          },
          onChanged: (v) => newName = v.trim(),
        ),
      ),
      onConfirm: () async {
        if (!(formKey.currentState?.validate() ?? false)) {
          return;
        }
        Get.back();
        await renameScript(
          scriptService: scriptService,
          oldName: oldName,
          newName: newName,
        );
      },
      onCancel: () {},
    );
  }

  static Future<void> showDeleteDialog({
    required ScriptService scriptService,
    required String name,
  }) async {
    final canDelete = await scriptService.tryCloseScriptWithReason(name);
    if (!canDelete) return;

    await Get.defaultDialog(
      title: I18n.delete.tr,
      textConfirm: I18n.confirm.tr,
      textCancel: I18n.cancel.tr,
      middleText: '${I18n.deleteConfirm.tr} "$name"?',
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

