import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/common/models/config_drag_payload.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/config_collection_tile.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigCollectionPanel extends StatefulWidget {
  static const _compactHeaderActionWidth = 108.0;
  static const _compactHeaderThreshold = 220.0;
  static const _compactFilterThreshold = 150.0;
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
  State<ConfigCollectionPanel> createState() => _ConfigCollectionPanelState();
}

class _ConfigCollectionPanelState extends State<ConfigCollectionPanel> {
  static const _autoScrollEdgeExtent = 56.0;
  static const _autoScrollStep = 10.0;

  /// Tracks whether the compact filter row should show the search field.
  bool _showCompactSearch = false;

  /// Controller reused when the compact search field is visible.
  late final TextEditingController _searchController;
  final ScrollController _listScrollController = ScrollController();
  final GlobalKey _listViewportKey = GlobalKey();
  Timer? _autoScrollTimer;
  double _autoScrollDirection = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          final activeDragPayload = widget.controller.activeDragPayload.value;
          if (activeDragPayload == null) {
            _stopAutoScroll();
          }
          final scripts = widget.controller.visibleScripts;
          final hasConfigs = widget.controller.orderedScripts.isNotEmpty;
          final searchValue = widget.controller.searchQuery.value;
          if (_searchController.text != searchValue) {
            _searchController.value = TextEditingValue(
              text: searchValue,
              selection: TextSelection.collapsed(offset: searchValue.length),
            );
          }
          final listView = DragTarget<ConfigDragPayload>(
            onWillAcceptWithDetails: (_) => true,
            onMove: (details) => _handleDragMove(details.offset),
            onLeave: (_) => _stopAutoScroll(),
            builder: (context, _, __) => SizedBox.expand(
              key: _listViewportKey,
              child: ListView.separated(
                controller: _listScrollController,
                itemCount: scripts.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) => _buildDropTargetTile(
                  context,
                  scripts[index],
                ),
              ),
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
                fillHeight: widget.fillHeight,
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

  /// Wraps one config tile in the drop target used by drag-copy flows.
  Widget _buildDropTargetTile(BuildContext context, ScriptModel script) {
    return DragTarget<ConfigDragPayload>(
      onWillAcceptWithDetails: (details) {
        return _canAcceptPayload(script.name, details.data);
      },
      onMove: (details) => _handleDragMove(details.offset),
      onLeave: (_) => _stopAutoScroll(),
      onAcceptWithDetails: (details) async {
        _stopAutoScroll();
        widget.controller.clearConfigDrag();
        await widget.controller.acceptConfigDrag(
          payload: details.data,
          destinationConfig: script.name,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final candidate = candidateData.isNotEmpty ? candidateData.first : null;
        final isHighlighted = _canAcceptPayload(script.name, candidate);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.28)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          child: ConfigCollectionTile(
            controller: widget.controller,
            script: script,
            onTap: () => widget.onActivateScript(script.name),
            onTogglePower: () => widget.onTogglePower(
              script.name,
              script.state.value != ScriptState.running,
            ),
            onRename: () => widget.onRenameScript(script.name),
            onDelete: () => widget.onDeleteScript(script.name),
          ),
        );
      },
    );
  }

  /// Returns whether the dragged payload may be dropped on the config row.
  bool _canAcceptPayload(String destinationConfig, ConfigDragPayload? payload) {
    return payload != null &&
        payload.canDropOn(destinationConfig) &&
        !widget.controller.isDragCopyPendingFor(destinationConfig);
  }

  /// Starts or stops list auto-scroll based on the current drag location.
  void _handleDragMove(Offset globalOffset) {
    final renderObject = _listViewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      _stopAutoScroll();
      return;
    }
    final localOffset = renderObject.globalToLocal(globalOffset);
    final viewportHeight = renderObject.size.height;
    if (localOffset.dy <= _autoScrollEdgeExtent) {
      _startAutoScroll(-1);
      return;
    }
    if (localOffset.dy >= viewportHeight - _autoScrollEdgeExtent) {
      _startAutoScroll(1);
      return;
    }
    _stopAutoScroll();
  }

  /// Creates one periodic scroll loop in the given direction.
  void _startAutoScroll(double direction) {
    if (_autoScrollTimer != null && _autoScrollDirection == direction) {
      return;
    }
    _stopAutoScroll();
    _autoScrollDirection = direction;
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 24),
      (_) => _tickAutoScroll(),
    );
  }

  /// Advances the list while drag hover stays inside one edge zone.
  void _tickAutoScroll() {
    if (!_listScrollController.hasClients) {
      _stopAutoScroll();
      return;
    }
    final position = _listScrollController.position;
    final currentOffset = position.pixels;
    final nextOffset = (currentOffset + _autoScrollDirection * _autoScrollStep)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((nextOffset - currentOffset).abs() < 0.5) {
      _stopAutoScroll();
      return;
    }
    _listScrollController.jumpTo(nextOffset);
  }

  /// Cancels any running auto-scroll loop.
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollDirection = 0;
  }

  Widget _buildHeader(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;
    final separatorStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.outline,
      fontWeight: FontWeight.w600,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeader = constraints.maxWidth <
            ConfigCollectionPanel._compactHeaderThreshold;
        final title = _HeaderTitle(
          controller: widget.controller,
          style: style,
          separatorStyle: separatorStyle,
          centered: compactHeader,
        );
        final actions = SizedBox(
          width: ConfigCollectionPanel._compactHeaderActionWidth,
          child: _HeaderActions(
            controller: widget.controller,
            refreshingScripts: widget.refreshingScripts,
            loadingAddScript: widget.loadingAddScript,
            onRefreshScriptsTap: widget.onRefreshScriptsTap,
            onAddScriptTap: widget.onAddScriptTap,
            centered: compactHeader,
          ),
        );
        if (!compactHeader) {
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 8),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: title),
            const SizedBox(height: 8),
            Center(child: actions),
          ],
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context) {
    final filter = widget.controller.stateFilter.value;
    final isFiltered = filter != HomeScriptStateFilter.all;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactFilters = constraints.maxWidth <
            ConfigCollectionPanel._compactFilterThreshold;
        final filterButton = _FilterButton(
          filter: filter,
          isFiltered: isFiltered,
          onSelected: widget.controller.setStateFilterValue,
          stateLabel: _stateLabel,
        );
        if (!compactFilters) {
          _showCompactSearch = false;
          return Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _searchController,
                  onChanged: widget.controller.setSearchQuery,
                ),
              ),
              const SizedBox(width: 8),
              filterButton,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_showCompactSearch) ...[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: widget.controller.setSearchQuery,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Center(
              child: IntrinsicWidth(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: I18n.homeScriptSearchHint.tr,
                      onPressed: _toggleCompactSearch,
                      constraints:
                          const BoxConstraints.tightFor(width: 40, height: 40),
                      icon: Icon(
                        _showCompactSearch
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                      ),
                    ),
                    filterButton,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Toggles the compact search field shown above the filter buttons.
  void _toggleCompactSearch() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showCompactSearch = !_showCompactSearch;
    });
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

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({
    required this.controller,
    required this.style,
    required this.separatorStyle,
    required this.centered,
  });

  final HomeDashboardController controller;
  final TextStyle? style;
  final TextStyle? separatorStyle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          I18n.scriptList.tr,
          style: style,
        ),
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
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.controller,
    required this.refreshingScripts,
    required this.loadingAddScript,
    required this.onRefreshScriptsTap,
    required this.onAddScriptTap,
    required this.centered,
  });

  final HomeDashboardController controller;
  final bool refreshingScripts;
  final bool loadingAddScript;
  final VoidCallback onRefreshScriptsTap;
  final VoidCallback onAddScriptTap;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          centered ? MainAxisAlignment.center : MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: I18n.homeConnectionRetryAction.tr,
          onPressed: refreshingScripts ? null : onRefreshScriptsTap,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
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
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
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
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
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
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: I18n.homeScriptSearchHint.tr,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.filter,
    required this.isFiltered,
    required this.onSelected,
    required this.stateLabel,
  });

  final HomeScriptStateFilter filter;
  final bool isFiltered;
  final ValueChanged<HomeScriptStateFilter> onSelected;
  final String Function(HomeScriptStateFilter value) stateLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: PopupMenuButton<HomeScriptStateFilter>(
        padding: EdgeInsets.zero,
        tooltip: stateLabel(filter),
        initialValue: filter,
        onSelected: onSelected,
        itemBuilder: (context) => ConfigCollectionPanel._visibleStateFilters
            .map(
              (value) => PopupMenuItem<HomeScriptStateFilter>(
                value: value,
                child: Text(stateLabel(value)),
              ),
            )
            .toList(),
        icon: Icon(
          Icons.filter_list_rounded,
          color: isFiltered ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );
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
