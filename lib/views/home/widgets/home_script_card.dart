import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/views/home/widgets/home_constants.dart';
import 'package:oasx/views/home/widgets/home_task_summary.dart';

enum HomeScriptMenuAction {
  rename,
  delete,
}

class HomeScriptCard extends StatelessWidget {
  const HomeScriptCard({
    super.key,
    required this.scriptModel,
    required this.scriptService,
    required this.onOpenOverview,
    required this.onMenuSelected,
  });

  final ScriptModel scriptModel;
  final ScriptService scriptService;
  final VoidCallback onOpenOverview;
  final ValueChanged<HomeScriptMenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kHomeScriptCardHeight,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpenOverview,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Obx(() {
              final state = scriptModel.state.value;
              final isRunning = state == ScriptState.running;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scriptModel.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _ScriptStateIndicator(state: state),
                      IconButton(
                        tooltip: isRunning ? I18n.stopped.tr : I18n.running.tr,
                        onPressed: () async {
                          if (isRunning) {
                            await scriptService.stopScript(scriptModel.name);
                          } else {
                            await scriptService.startScript(scriptModel.name);
                          }
                        },
                        icon: const Icon(Icons.power_settings_new_rounded),
                        isSelected: isRunning,
                      ),
                      PopupMenuButton<HomeScriptMenuAction>(
                        tooltip: I18n.setting.tr,
                        onSelected: onMenuSelected,
                        itemBuilder: (context) => [
                          PopupMenuItem<HomeScriptMenuAction>(
                            value: HomeScriptMenuAction.rename,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit, size: 18),
                                const SizedBox(width: 4),
                                Text(I18n.rename.tr),
                              ],
                            ),
                          ),
                          PopupMenuItem<HomeScriptMenuAction>(
                            value: HomeScriptMenuAction.delete,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.delete,
                                    size: 18, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(I18n.delete.tr),
                              ],
                            ),
                          ),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.settings_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  HomeTaskSummary(scriptModel: scriptModel),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _ScriptStateIndicator extends StatelessWidget {
  const _ScriptStateIndicator({required this.state});

  final ScriptState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: switch (state) {
        ScriptState.running => const SpinKitChasingDots(
            color: Colors.green,
            size: 22,
          ),
        ScriptState.inactive =>
          const Icon(Icons.donut_large, size: 24, color: Colors.grey),
        ScriptState.warning =>
          const SpinKitDoubleBounce(color: Colors.orange, size: 24),
        ScriptState.updating => const Icon(
            Icons.browser_updated_rounded,
            size: 24,
            color: Colors.blue,
          ),
      },
    );
  }
}
