import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/home_dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/config_collection_tile.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigCollectionPanel extends StatelessWidget {
  static const _visibleStateFilters = [
    HomeScriptStateFilter.all,
    HomeScriptStateFilter.running,
    HomeScriptStateFilter.stopped,
    HomeScriptStateFilter.abnormal,
  ];

  const ConfigCollectionPanel({
    super.key,
    required this.controller,
    required this.fillHeight,
    required this.loadingAddScript,
    required this.refreshingScripts,
    required this.onAddScriptTap,
    required this.onRefreshScriptsTap,
    required this.onActivateScript,
    required this.onTogglePower,
    required this.onRenameScript,
    required this.onDeleteScript,
  });

  final HomeDashboardController controller;
  final bool fillHeight;
  final bool loadingAddScript;
  final bool refreshingScripts;
  final VoidCallback onAddScriptTap;
  final VoidCallback onRefreshScriptsTap;
  final Future<void> Function(String scriptName) onActivateScript;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;
  final Future<void> Function(String scriptName) onRenameScript;
  final Future<void> Function(String scriptName) onDeleteScript;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          final scripts = controller.visibleScripts;
          final hasConfigs = controller.orderedScripts.isNotEmpty;
          final listView = ListView.separated(
            itemCount: scripts.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) => ConfigCollectionTile(
              controller: controller,
              script: scripts[index],
              state: controller.scriptCollectionStateFor(scripts[index]),
              onTap: () => onActivateScript(scripts[index].name),
              onTogglePower: () => onTogglePower(
                scripts[index].name,
                scripts[index].state.value != ScriptState.running,
              ),
              onRename: () => onRenameScript(scripts[index].name),
              onDelete: () => onDeleteScript(scripts[index].name),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              _buildFilters(context),
              const SizedBox(height: 10),
              ExpandedOrSizedBox(
                fillHeight: fillHeight,
                child: hasConfigs
                    ? listView
                    : Center(
                        child: Text(
                          I18n.homeEmptyScriptHint.tr,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;
    final separatorStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.outline,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Text(
          I18n.scriptList.tr,
          style: style,
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text:
                    '${controller.countScriptsByState(HomeScriptStateFilter.running)}',
                style: style?.copyWith(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: '/', style: separatorStyle),
              TextSpan(
                text:
                    '${controller.countScriptsByState(HomeScriptStateFilter.stopped)}',
                style: style?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: '/', style: separatorStyle),
              TextSpan(
                text:
                    '${controller.countScriptsByState(HomeScriptStateFilter.abnormal)}',
                style: style?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: I18n.homeConnectionRetryAction.tr,
          onPressed: refreshingScripts ? null : onRefreshScriptsTap,
          icon: refreshingScripts
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: controller.isLinkModeEnabled.value
              ? I18n.closeTheLinker.tr
              : I18n.turnOnTheLinker.tr,
          onPressed: controller.toggleLinkMode,
          style: IconButton.styleFrom(
            backgroundColor: controller.isLinkModeEnabled.value
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            foregroundColor: controller.isLinkModeEnabled.value
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
          icon: const Icon(Icons.link_rounded),
        ),
        IconButton(
          tooltip: I18n.configAdd.tr,
          onPressed: loadingAddScript ? null : onAddScriptTap,
          icon: loadingAddScript
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final filter = controller.stateFilter.value;
    final isFiltered = filter != HomeScriptStateFilter.all;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: controller.searchQuery.value,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: I18n.homeScriptSearchHint.tr,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: controller.setSearchQuery,
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<HomeScriptStateFilter>(
          tooltip: _stateLabel(filter),
          initialValue: filter,
          onSelected: controller.setStateFilterValue,
          itemBuilder: (context) => _visibleStateFilters
              .map(
                (value) => PopupMenuItem<HomeScriptStateFilter>(
                  value: value,
                  child: Text(_stateLabel(value)),
                ),
              )
              .toList(),
          icon: Icon(
            Icons.filter_list_rounded,
            color: isFiltered ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  String _stateLabel(HomeScriptStateFilter value) {
    return switch (value) {
      HomeScriptStateFilter.all => I18n.selectAll.tr,
      HomeScriptStateFilter.running => I18n.run.tr,
      HomeScriptStateFilter.abnormal => I18n.homeScriptAbnormal.tr,
      HomeScriptStateFilter.stopped => I18n.stop.tr,
      HomeScriptStateFilter.offline => I18n.homeScriptOffline.tr,
    };
  }
}

class ExpandedOrSizedBox extends StatelessWidget {
  const ExpandedOrSizedBox({
    super.key,
    required this.fillHeight,
    required this.child,
  });

  final bool fillHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (fillHeight) {
      return Expanded(child: child);
    }
    return SizedBox(height: 320, child: child);
  }
}

