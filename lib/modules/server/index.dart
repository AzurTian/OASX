library server;

import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/common/index.dart';
import 'package:oasx/modules/log/log_mixin.dart';
import 'package:oasx/modules/log/log_widget.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:process_run/shell.dart';
import 'dart:io';
import 'package:styled_widget/styled_widget.dart';
import 'package:code_editor/code_editor.dart';

import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/modules/home/controllers/home_dashboard_controller.dart';
import 'package:oasx/service/script_service.dart';

part 'deploy_view.dart';
part 'controllers/server_controller.dart';
part 'controllers/server_controller_deploy_io.dart';

class ServerView extends StatelessWidget {
  const ServerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformAppBar(context, routePath: '/server'),
      floatingActionButton: startServerButton(),
      body: _body(),
    );
  }

  Widget _body() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      ServerController serverController = Get.find<ServerController>();
      return SingleChildScrollView(
          child: Column(
        spacing: 6,
        children: [
          ExpansionTileGroup(
            toggleType: ToggleType.expandOnlyCurrent,
            children: [
              path(context),
              deploy(constraints.maxHeight - 200, context),
            ],
          ),
          LogWidget(
                  key: ValueKey(serverController.hashCode),
                  controller: serverController,
                  title: I18n.setupLog.tr)
              .constrained(height: constraints.maxHeight - 200)
        ],
      ).padding(right: 10, left: 10));
    });
  }

  ExpansionTileItem path(BuildContext context) {
    Widget path = GetX<ServerController>(builder: (controller) {
      return <Widget>[
        Text(I18n.rootPathServer.tr,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(
          width: 10,
        ),
        Text(controller.rootPathServer.value),
        TextButton(
            onPressed: () async {
              String? selectedDirectory =
                  await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory == null) {
                // User canceled the picker
                return;
              }
              controller.updateRootPathServer(selectedDirectory);
            },
            child: Text(I18n.selectRootPathServer.tr))
      ].toRow();
    });
    Widget pass = GetX<ServerController>(builder: (controller) {
      return <Widget>[
        controller.rootPathAuthenticated.value
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error, color: Colors.red),
        Text(
          controller.rootPathAuthenticated.value
              ? I18n.rootPathCorrect.tr
              : I18n.rootPathIncorrect.tr,
          // style: Theme.of(context).textTheme.titleMedium
        ),
      ].toRow();
    });

    return ExpansionTileItem(
      initiallyExpanded: false,
      isHasTopBorder: false,
      isHasBottomBorder: false,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.24),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      title: pass,
      children: [
        path,
        Text(I18n.rootPathServerHelp.tr),
      ],
    );
  }

  ExpansionTileItem deploy(double maxHeight, BuildContext context) {
    return ExpansionTileItem(
      initiallyExpanded: false,
      isHasTopBorder: false,
      isHasBottomBorder: false,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.24),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      title: Text(I18n.setupDeploy.tr,
          style: Theme.of(context).textTheme.titleMedium),
      children: [
        SingleChildScrollView(
          child: code(maxHeight - 50),
        ).constrained(height: maxHeight)
      ],
    );
  }

  Widget startServerButton() {
    return GetX<ServerController>(builder: (controller) {
      if (controller.rootPathAuthenticated.value) {
        return FloatingActionButton(
            child: Obx(() => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: controller.isDeployLoading.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.auto_mode_rounded),
                )),
            onPressed: () {
              if (controller.isDeployLoading.value) return;
              controller.run();
            });
      } else {
        return const SizedBox(
          width: 100,
          height: 100,
        );
      }
    });
  }

  Widget code(double maxHeight) {
    return GetX<ServerController>(builder: (controller) {
      FileEditor file = FileEditor(
        name: "deploy.yaml",
        language: "yaml",
        code: controller.deployContent.value, // [code] needs a string
      );
      EditorModel model = EditorModel(
        files: [file], // the files created above
        // you can customize the editor as you want
        styleOptions: EditorModelStyleOptions(
          heightOfContainer: maxHeight,
          // theme: githubTheme,
        ),
      );
      return CodeEditor(
        model: model,
        formatters: const ["yaml"],
        onSubmit: (String language, String value) {
          controller.writeDeploy(value);
        },
      );
    });
  }
}






