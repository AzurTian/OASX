library overview;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/component/log/log_widget.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/translation/i18n_content.dart';

part '../../controller/overview/overview_controller.dart';
part '../../controller/overview/taskitem_model.dart';

class OverviewRouteView extends StatelessWidget {
  const OverviewRouteView({super.key});

  @override
  Widget build(BuildContext context) {
    final scriptName = Get.parameters['script']?.trim() ?? '';
    return Overview(scriptName: scriptName, standalone: true);
  }
}

class Overview extends StatelessWidget {
  const Overview({
    super.key,
    required this.scriptName,
    this.standalone = false,
  });

  final String scriptName;
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!standalone) {
      return content;
    }
    return Scaffold(
      appBar: buildPlatformAppBar(context, routePath: '/overview'),
      body: SafeArea(child: content),
    );
  }

  Widget _buildContent(BuildContext context) {
    final scriptService = Get.find<ScriptService>();
    final normalizedName = scriptName.trim();
    if (normalizedName.isEmpty ||
        scriptService.findScriptModel(normalizedName) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute == '/overview') {
          Get.offAllNamed('/home');
        }
      });
      return Center(child: Text(I18n.no_data.tr));
    }

    final overviewController = _getOrCreateOverviewController(normalizedName);
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: SizedBox.expand(
              child: LogWidget(
                key: ValueKey(overviewController.hashCode),
                controller: overviewController,
                title: I18n.log.tr,
                enableCollapse: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  OverviewController _getOrCreateOverviewController(String name) {
    if (Get.isRegistered<OverviewController>(tag: name)) {
      return Get.find<OverviewController>(tag: name);
    }
    return Get.put(
      OverviewController(name: name),
      tag: name,
      permanent: true,
    );
  }
}
