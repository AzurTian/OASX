import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/common/widgets/add_config_dialog.dart';
import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/widgets/config_workbench.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/utils/platform_utils.dart';

part 'home_view_actions.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.standalone = true});

  final bool standalone;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final scriptService = Get.find<ScriptService>();
  final controller = Get.find<HomeDashboardController>();
  bool _isAddingScript = false;
  bool _isRefreshingScripts = false;

  void _setAddingScript(bool value) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isAddingScript = value;
    });
  }

  void _setRefreshingScripts(bool value) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isRefreshingScripts = value;
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      checkUpdate(cachePolicy: UpdateCheckPolicy.autoCached);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.checkStartupConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Stack(
        children: [
          _buildDashboardBody(),
          Obx(() {
            final message = controller.startupLoadingMessage.value;
            if (message.isEmpty) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.25),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        message.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );

    if (!widget.standalone) {
      return body;
    }

    return Scaffold(
      appBar: buildPlatformAppBar(
        context,
        routePath: '/home',
        trailingActions: PlatformUtils.isDesktop
            ? [
                IconButton(
                  tooltip: I18n.setting.tr,
                  onPressed: () => Get.toNamed('/settings'),
                  icon: const Icon(Icons.settings_rounded),
                ),
              ]
            : const [],
      ),
      body: body,
    );
  }
}

