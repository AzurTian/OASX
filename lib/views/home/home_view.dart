import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/controller/home/home_dashboard_controller.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/views/common/add_config_dialog.dart';
import 'package:oasx/views/home/home_script_actions.dart';
import 'package:oasx/views/home/widgets/home_overview_header.dart';
import 'package:oasx/views/home/widgets/home_script_card.dart';
import 'package:oasx/views/home/widgets/home_script_grid.dart';
import 'package:oasx/views/layout/appbar.dart';

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

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      checkUpdate();
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
            if (!controller.isStartupAutoDeploying.value) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(),
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
      appBar: buildPlatformAppBar(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/settings'),
        child: const Icon(Icons.settings_rounded),
      ),
      body: body,
    );
  }

  Widget _buildDashboardBody() {
    return Column(
      children: [
        HomeOverviewHeader(
          scriptService: scriptService,
          loadingAddScript: _isAddingScript,
          onAddScriptTap: _onAddScriptCardTap,
        ),
        Expanded(
          child: Obx(() {
            final scripts = _orderedScripts();
            return HomeScriptGrid(
              scripts: scripts,
              scriptService: scriptService,
              onOpenLog: _openLogPage,
              onScriptMenuSelected: _onScriptMenuSelected,
            );
          }),
        ),
      ],
    );
  }

  List<ScriptModel> _orderedScripts() {
    final orderedNames = scriptService.scriptOrderList;
    final scriptMap = scriptService.scriptModelMap;
    final orderedScripts = <ScriptModel>[];
    for (final name in orderedNames) {
      final model = scriptMap[name];
      if (model != null) {
        orderedScripts.add(model);
      }
    }
    return orderedScripts;
  }

  Future<void> _onAddScriptCardTap() async {
    if (_isAddingScript) {
      return;
    }
    await showAddConfigDialog(
      context,
      onSubmitting: () {
        if (!mounted) return;
        setState(() {
          _isAddingScript = true;
        });
      },
      onSubmitDone: () {
        if (!mounted) return;
        setState(() {
          _isAddingScript = false;
        });
      },
    );
  }

  void _openLogPage(String scriptName) {
    Get.toNamed('/overview', parameters: {'script': scriptName});
  }

  Future<void> _onScriptMenuSelected(
      HomeScriptMenuAction action, String scriptName) async {
    await HomeScriptActions.onMenuSelected(
      action: action,
      scriptName: scriptName,
      scriptService: scriptService,
    );
  }
}
