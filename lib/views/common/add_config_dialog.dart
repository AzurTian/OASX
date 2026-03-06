import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';

Future<bool> showAddConfigDialog(
  BuildContext context, {
  VoidCallback? onSubmitting,
  VoidCallback? onSubmitDone,
}) async {
  String newName = await ApiClient().getNewConfigName();
  final fetchedConfigAll = await ApiClient().getConfigAll();
  final configAll =
      fetchedConfigAll.isEmpty ? <String>['template'] : fetchedConfigAll;
  final defaultTemplate = configAll.contains('template')
      ? 'template'
      : (configAll.isNotEmpty ? configAll.first : 'template');
  final selectedTemplate = defaultTemplate.obs;
  final isSubmitting = false.obs;
  if (!context.mounted) {
    return false;
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(I18n.config_add.tr),
        content: Obx(() {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (MediaQuery.sizeOf(dialogContext).height * 0.45)
                  .clamp(220.0, 420.0)
                  .toDouble(),
            ),
            child: SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(I18n.new_name.tr),
                    TextFormField(
                      initialValue: newName,
                      enabled: !isSubmitting.value,
                      onChanged: (value) {
                        newName = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(I18n.config_copy_from_exist.tr),
                    DropdownButton<String>(
                      value: selectedTemplate.value,
                      menuMaxHeight: 300,
                      isExpanded: true,
                      items: configAll
                          .map<DropdownMenuItem<String>>(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting.value
                          ? null
                          : (value) {
                              if (value == null) return;
                              selectedTemplate.value = value;
                            },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        actions: [
          TextButton(
            onPressed: () {
              if (isSubmitting.value) return;
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(I18n.cancel.tr),
          ),
          Obx(() {
            return FilledButton(
              onPressed: isSubmitting.value
                  ? null
                  : () async {
                      isSubmitting.value = true;
                      onSubmitting?.call();
                      try {
                        final navList = await ApiClient()
                            .configCopy(newName, selectedTemplate.value);
                        final scripts = navList.where((e) => e != 'Home');
                        Get.find<ScriptService>().syncScriptOrder(scripts);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(true);
                        }
                      } finally {
                        isSubmitting.value = false;
                        onSubmitDone?.call();
                      }
                    },
              child: isSubmitting.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(I18n.confirm.tr),
            );
          }),
        ],
      );
    },
  );

  return result == true;
}
