import 'package:code_editor/code_editor.dart';
import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/log/log_widget.dart';
import 'package:oasx/modules/server/controllers/server_controller.dart';
import 'package:oasx/translation/i18n_content.dart';

class ServerView extends StatelessWidget {
  const ServerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformAppBar(context, routePath: '/server'),
      floatingActionButton: _buildStartServerButton(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final serverController = Get.find<ServerController>();
        return SingleChildScrollView(
          child: Column(
            spacing: 6,
            children: [
              ExpansionTileGroup(
                toggleType: ToggleType.expandOnlyCurrent,
                children: [
                  _buildPathSection(context),
                  _buildDeploySection(constraints.maxHeight - 200, context),
                ],
              ),
              LogWidget(
                key: ValueKey(serverController.hashCode),
                controller: serverController,
                title: I18n.setupLog.tr,
              ).constrained(height: constraints.maxHeight - 200),
            ],
          ).padding(right: 10, left: 10),
        );
      },
    );
  }

  ExpansionTileItem _buildPathSection(BuildContext context) {
    final path = GetX<ServerController>(builder: (controller) {
      return <Widget>[
        Text(
          I18n.rootPathServer.tr,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 10),
        Text(controller.rootPathServer.value),
        TextButton(
          onPressed: () async {
            final selectedDirectory =
                await FilePicker.platform.getDirectoryPath();
            if (selectedDirectory == null) {
              return;
            }
            controller.updateRootPathServer(selectedDirectory);
          },
          child: Text(I18n.selectRootPathServer.tr),
        ),
      ].toRow();
    });
    final pass = GetX<ServerController>(builder: (controller) {
      return <Widget>[
        controller.rootPathAuthenticated.value
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error, color: Colors.red),
        Text(
          controller.rootPathAuthenticated.value
              ? I18n.rootPathCorrect.tr
              : I18n.rootPathIncorrect.tr,
        ),
      ].toRow();
    });

    return ExpansionTileItem(
      initiallyExpanded: false,
      isHasTopBorder: false,
      isHasBottomBorder: false,
      collapsedBackgroundColor: Theme.of(context)
          .colorScheme
          .secondaryContainer
          .withValues(alpha: 0.24),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      title: pass,
      children: [
        path,
        Text(I18n.rootPathServerHelp.tr),
      ],
    );
  }

  ExpansionTileItem _buildDeploySection(
    double maxHeight,
    BuildContext context,
  ) {
    return ExpansionTileItem(
      initiallyExpanded: false,
      isHasTopBorder: false,
      isHasBottomBorder: false,
      collapsedBackgroundColor: Theme.of(context)
          .colorScheme
          .secondaryContainer
          .withValues(alpha: 0.24),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      title: Text(
        I18n.setupDeploy.tr,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      children: [
        SingleChildScrollView(
          child: _buildCodeEditor(maxHeight - 50),
        ).constrained(height: maxHeight),
      ],
    );
  }

  Widget _buildStartServerButton() {
    return GetX<ServerController>(builder: (controller) {
      if (!controller.rootPathAuthenticated.value) {
        return const SizedBox(width: 100, height: 100);
      }
      return FloatingActionButton(
        onPressed: () {
          if (controller.isDeployLoading.value) {
            return;
          }
          controller.run();
        },
        child: Obx(
          () => AnimatedSwitcher(
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
          ),
        ),
      );
    });
  }

  Widget _buildCodeEditor(double maxHeight) {
    return GetX<ServerController>(builder: (controller) {
      final file = FileEditor(
        name: 'deploy.yaml',
        language: 'yaml',
        code: controller.deployContent.value,
      );
      final model = EditorModel(
        files: [file],
        styleOptions: EditorModelStyleOptions(
          heightOfContainer: maxHeight,
        ),
      );
      return CodeEditor(
        model: model,
        formatters: const ['yaml'],
        onSubmit: (language, value) {
          controller.writeDeploy(value);
        },
      );
    });
  }
}
