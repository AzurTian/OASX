import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:oasx/controller/home/home_dashboard_controller.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/views/common/add_config_dialog.dart';
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
                color: Colors.black.withOpacity(0.25),
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
        _OverviewHeader(scriptService: scriptService),
        Expanded(
          child: Obx(() {
            final scripts = _orderedScripts();
            return LayoutBuilder(
              builder: (context, constraints) {
                const minCardWidth = 340.0;
                final crossAxisCount =
                    max(1, (constraints.maxWidth / minCardWidth).floor());
                final totalCount = scripts.length + 1;

                return MasonryGridView.count(
                  padding: const EdgeInsets.all(12),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    if (index == scripts.length) {
                      return _AddScriptCard(
                        loading: _isAddingScript,
                        onTap: _onAddScriptCardTap,
                      );
                    }
                    final script = scripts[index];
                    return _ScriptCard(
                      scriptModel: script,
                      scriptService: scriptService,
                      onOpenOverview: () => _openOverview(script.name),
                      onMenuSelected: (action) =>
                          _onScriptMenuSelected(action, script.name),
                    );
                  },
                );
              },
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

  void _openOverview(String scriptName) {
    Get.toNamed('/overview', parameters: {'script': scriptName});
  }

  Future<void> _onScriptMenuSelected(
      _ScriptMenuAction action, String scriptName) async {
    switch (action) {
      case _ScriptMenuAction.rename:
        await _showRenameDialog(scriptName);
        break;
      case _ScriptMenuAction.delete:
        await _showDeleteDialog(scriptName);
        break;
    }
  }

  Future<void> _showRenameDialog(String oldName) async {
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
          )),
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

  Future<void> _showDeleteDialog(String name) async {
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

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.scriptService,
  });

  final ScriptService scriptService;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Obx(() {
            final scripts = scriptService.scriptOrderList
                .map((name) => scriptService.scriptModelMap[name])
                .whereType<ScriptModel>()
                .toList();
            final runningCount = scripts
                .where((e) => e.state.value == ScriptState.running)
                .length;
            final totalCount = scripts.length;

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final numberSize = compact ? 34.0 : 42.0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18n.home_overview_control.tr,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: compact ? 12 : 24,
                      runSpacing: 12,
                      children: [
                        _CountMetric(
                          label: I18n.running.tr,
                          value: '$runningCount',
                          numberSize: numberSize,
                          color: Colors.green,
                        ),
                        _CountMetric(
                          label: I18n.home_total_scripts.tr,
                          value: '$totalCount',
                          numberSize: numberSize,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _CountMetric extends StatelessWidget {
  const _CountMetric({
    required this.label,
    required this.value,
    required this.numberSize,
    required this.color,
  });

  final String label;
  final String value;
  final double numberSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: numberSize,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddScriptCard extends StatelessWidget {
  const _AddScriptCard({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 100,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.add_rounded, size: 36),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ScriptMenuAction {
  rename,
  delete,
}

class _ScriptCard extends StatelessWidget {
  const _ScriptCard({
    required this.scriptModel,
    required this.scriptService,
    required this.onOpenOverview,
    required this.onMenuSelected,
  });

  final ScriptModel scriptModel;
  final ScriptService scriptService;
  final VoidCallback onOpenOverview;
  final ValueChanged<_ScriptMenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                        style: const TextStyle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StateChip(state: state),
                    const SizedBox(width: 8),
                    PopupMenuButton<_ScriptMenuAction>(
                      tooltip: I18n.setting.tr,
                      onSelected: onMenuSelected,
                      itemBuilder: (context) => [
                        PopupMenuItem<_ScriptMenuAction>(
                          value: _ScriptMenuAction.rename,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit, size: 18),
                              const SizedBox(width: 4),
                              Text(I18n.rename.tr),
                            ],
                          ),
                        ),
                        PopupMenuItem<_ScriptMenuAction>(
                          value: _ScriptMenuAction.delete,
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
                    const SizedBox(width: 2),
                    Switch(
                      value: isRunning,
                      onChanged: (enable) async {
                        if (enable) {
                          await scriptService.startScript(scriptModel.name);
                        } else {
                          await scriptService.stopScript(scriptModel.name);
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 14),
                _TaskSummary(scriptModel: scriptModel),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final ScriptState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      ScriptState.running => (I18n.running.tr, Colors.green),
      ScriptState.inactive => (I18n.stopped.tr, Colors.grey),
      ScriptState.warning => (I18n.warning.tr, Colors.orange),
      ScriptState.updating => (I18n.connecting.tr, Colors.blueGrey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

enum _TaskType {
  none,
  running,
  pending,
  waiting,
}

class _TaskData {
  const _TaskData({
    required this.type,
    required this.label,
    required this.name,
    this.time = '',
  });

  final _TaskType type;
  final String label;
  final String name;
  final String time;
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({required this.scriptModel});

  final ScriptModel scriptModel;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final task = _pickTask();
      if (task.type == _TaskType.none) {
        return Text(I18n.home_unconfigured_task.tr,
            style: const TextStyle(fontSize: 13));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          _AutoScrollText(
            text: task.name.tr,
            fontSize: 13,
          ),
          if (task.type == _TaskType.waiting &&
              task.time.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${I18n.time.tr}: ${task.time}',
                style: const TextStyle(fontSize: 12)),
          ],
        ],
      );
    });
  }

  _TaskData _pickTask() {
    final runningTask = scriptModel.runningTask.value;
    final runningName = runningTask.taskName.value.trim();
    if (runningName.isNotEmpty) {
      return _TaskData(
          type: _TaskType.running,
          label: I18n.home_running_task.tr,
          name: runningName);
    }

    final pending = scriptModel.pendingTaskList;
    if (pending.isNotEmpty) {
      final task = pending.first;
      return _TaskData(
        type: _TaskType.pending,
        label: I18n.home_pending_task.tr,
        name: task.taskName.value.trim(),
      );
    }

    final waiting = scriptModel.waitingTaskList;
    if (waiting.isNotEmpty) {
      final task = waiting.first;
      return _TaskData(
        type: _TaskType.waiting,
        label: I18n.home_waiting_task.tr,
        name: task.taskName.value.trim(),
        time: task.nextRun.value.trim(),
      );
    }

    return const _TaskData(type: _TaskType.none, label: '', name: '');
  }
}

class _AutoScrollText extends StatefulWidget {
  const _AutoScrollText({
    required this.text,
    required this.fontSize,
  });

  final String text;
  final double fontSize;

  @override
  State<_AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<_AutoScrollText> {
  final ScrollController _scrollController = ScrollController();
  bool _loopRunning = false;

  @override
  void initState() {
    super.initState();
    _tryStartLoop();
  }

  @override
  void didUpdateWidget(covariant _AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _tryStartLoop(reset: true);
    }
  }

  void _tryStartLoop({bool reset = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (reset) {
        _scrollController.jumpTo(0);
      }
      if (_scrollController.position.maxScrollExtent <= 0 || _loopRunning) {
        return;
      }

      _loopRunning = true;
      while (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        final duration =
            Duration(milliseconds: max(1800, (maxExtent * 28).round()));
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted || !_scrollController.hasClients) {
          break;
        }
        await _scrollController.animateTo(
          maxExtent,
          duration: duration,
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted || !_scrollController.hasClients) {
          break;
        }
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      }
      _loopRunning = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: ListView(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          Text(widget.text, style: TextStyle(fontSize: widget.fontSize)),
        ],
      ),
    );
  }
}
