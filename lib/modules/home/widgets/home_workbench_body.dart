import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';

/// Hosts the responsive home workbench layout and divider interaction.
class HomeWorkbenchBody extends StatefulWidget {
  const HomeWorkbenchBody({
    super.key,
    required this.controller,
    required this.collectionBuilder,
    required this.detailsBuilder,
    required this.logs,
  });

  /// Home dashboard controller providing persisted split state.
  final HomeDashboardController controller;

  /// Builds the script collection pane for the resolved layout.
  final Widget Function(HomeWorkbenchLayoutMode layoutMode) collectionBuilder;

  /// Builds the active workbench pane for the resolved layout.
  final Widget Function(HomeWorkbenchLayoutMode layoutMode) detailsBuilder;

  /// Log center widget reused in three-pane mode.
  final Widget logs;

  @override
  State<HomeWorkbenchBody> createState() => _HomeWorkbenchBodyState();
}

class _HomeWorkbenchBodyState extends State<HomeWorkbenchBody> {
  /// Tracks whether drag collapse has temporarily merged the log pane.
  bool _forceTwoPane = false;

  /// Remembers the last measured width to detect later resize expansions.
  double? _lastMeasuredWidth;

  /// Stores a live split ratio while the divider is actively dragging.
  double? _dragSplitRatio;

  /// Stores the raw detail width target while the divider is actively dragging.
  double? _dragTargetDetailsWidth;

  /// Stores the pane currently highlighted as a pending collapse target.
  HomeWorkbenchCollapseSide? _pendingCollapseSide;

  /// Stores the current pending collapse progress for visual feedback.
  double _pendingCollapseProgress = 0;

  /// Tracks whether releasing the pointer should commit the collapse.
  bool _collapseOnRelease = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final persistedSplitRatio = widget.controller.workbenchSplitRatio.value;
      return LayoutBuilder(
        builder: (context, constraints) {
          final layout = _resolveLayout(
            maxWidth: constraints.maxWidth,
            persistedSplitRatio: persistedSplitRatio,
          );
          final layoutMode = layout.mode;
          final collection = widget.collectionBuilder(layoutMode);
          final details = _buildPaneFrame(
            child: widget.detailsBuilder(layoutMode),
            highlighted: _pendingCollapseSide == HomeWorkbenchCollapseSide.workbench,
            progress: _pendingCollapseProgress,
          );
          if (layoutMode == HomeWorkbenchLayoutMode.threePane) {
            return Row(
              key: const ValueKey<String>('home-workbench-three-pane'),
              children: [
                SizedBox(width: kHomeWorkbenchScriptListWidth, child: collection),
                const SizedBox(width: kHomeWorkbenchPaneGap),
                SizedBox(width: layout.detailsWidth, child: details),
                _WorkbenchDivider(
                  onDragStart: () => _handleDragStart(layout),
                  onDragUpdate: (details) => _handleDragUpdate(details, layout),
                  onDragEnd: _handleDragEnd,
                  collapseSide: _pendingCollapseSide,
                  collapseProgress: _pendingCollapseProgress,
                ),
                SizedBox(
                  width: layout.logWidth,
                  child: _buildPaneFrame(
                    child: widget.logs,
                    highlighted: _pendingCollapseSide == HomeWorkbenchCollapseSide.logs,
                    progress: _pendingCollapseProgress,
                  ),
                ),
              ],
            );
          }
          if (layoutMode == HomeWorkbenchLayoutMode.twoPane) {
            return Row(
              key: const ValueKey<String>('home-workbench-two-pane'),
              children: [
                SizedBox(width: kHomeWorkbenchScriptListWidth, child: collection),
                const SizedBox(width: kHomeWorkbenchPaneGap),
                Expanded(child: details),
              ],
            );
          }
          return Obx(() {
            final showWorkspace =
                widget.controller.workbenchPage.value == HomeWorkbenchPage.workspace &&
                    widget.controller.activeScriptName.value.trim().isNotEmpty;
            return showWorkspace ? details : collection;
          });
        },
      );
    });
  }

  /// Resolves the active layout and restores three-pane mode after a resize.
  HomeWorkbenchLayout _resolveLayout({
    required double maxWidth,
    required double persistedSplitRatio,
  }) {
    final currentSplitRatio = _dragSplitRatio ?? persistedSplitRatio;
    final unrestrictedLayout = resolveHomeWorkbenchLayout(
      maxWidth: maxWidth,
      splitRatio: currentSplitRatio,
    );
    _scheduleThreePaneRestoreIfNeeded(maxWidth, unrestrictedLayout.mode);
    _lastMeasuredWidth = maxWidth;
    return resolveHomeWorkbenchLayout(
      maxWidth: maxWidth,
      splitRatio: currentSplitRatio,
      forceTwoPane: _forceTwoPane,
    );
  }

  /// Schedules restoration when the user widens the window after a collapse.
  void _scheduleThreePaneRestoreIfNeeded(
    double maxWidth,
    HomeWorkbenchLayoutMode unrestrictedMode,
  ) {
    final lastMeasuredWidth = _lastMeasuredWidth;
    final widthChanged = lastMeasuredWidth == null ||
        (maxWidth - lastMeasuredWidth).abs() > 0.5;
    if (!_forceTwoPane || !widthChanged || unrestrictedMode != HomeWorkbenchLayoutMode.threePane) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_forceTwoPane) {
        return;
      }
      setState(() {
        _forceTwoPane = false;
      });
    });
  }

  /// Starts tracking divider movement from the current three-pane width.
  void _handleDragStart(HomeWorkbenchLayout layout) {
    _dragSplitRatio = layout.appliedSplitRatio;
    _dragTargetDetailsWidth = layout.detailsWidth;
    _pendingCollapseSide = null;
    _pendingCollapseProgress = 0;
    _collapseOnRelease = false;
  }

  /// Updates the live split ratio while exposing a buffered collapse state.
  void _handleDragUpdate(DragUpdateDetails details, HomeWorkbenchLayout layout) {
    final currentTargetWidth = _dragTargetDetailsWidth ?? layout.detailsWidth;
    final nextTargetWidth = currentTargetWidth + details.delta.dx;
    final dragState = resolveHomeWorkbenchDragState(
      layout: layout,
      targetDetailsWidth: nextTargetWidth,
    );
    setState(() {
      _forceTwoPane = false;
      _dragTargetDetailsWidth = nextTargetWidth;
      _dragSplitRatio = dragState.splitRatio;
      _pendingCollapseSide = dragState.collapseSide;
      _pendingCollapseProgress = dragState.collapseProgress;
      _collapseOnRelease = dragState.shouldCollapseOnRelease;
    });
  }

  /// Persists the last valid split or commits a buffered collapse on release.
  void _handleDragEnd(DragEndDetails details) {
    if (!mounted) {
      return;
    }
    final dragSplitRatio = _dragSplitRatio;
    if (dragSplitRatio != null) {
      widget.controller.setWorkbenchSplitRatio(dragSplitRatio);
    }
    setState(() {
      _forceTwoPane = _collapseOnRelease;
      _dragSplitRatio = null;
      _dragTargetDetailsWidth = null;
      _pendingCollapseSide = null;
      _pendingCollapseProgress = 0;
      _collapseOnRelease = false;
    });
  }

  /// Builds a subtle pane highlight while a collapse is pending.
  Widget _buildPaneFrame({
    required Widget child,
    required bool highlighted,
    required double progress,
  }) {
    if (!highlighted) {
      return child;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.45 + progress * 0.35),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

class _WorkbenchDivider extends StatelessWidget {
  const _WorkbenchDivider({
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.collapseSide,
    required this.collapseProgress,
  });

  /// Callback fired when the user starts dragging the divider.
  final VoidCallback onDragStart;

  /// Callback fired for each horizontal drag delta.
  final ValueChanged<DragUpdateDetails> onDragUpdate;

  /// Callback fired when the drag gesture ends.
  final ValueChanged<DragEndDetails> onDragEnd;

  /// Side currently highlighted as the pending collapse target.
  final HomeWorkbenchCollapseSide? collapseSide;

  /// Normalized progress within the pending collapse buffer.
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant;
    final highlightColor =
        Colors.blueAccent.withValues(alpha: 0.12 + collapseProgress * 0.22);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => onDragStart(),
        onHorizontalDragUpdate: onDragUpdate,
        onHorizontalDragEnd: onDragEnd,
        child: SizedBox(
          width: kHomeWorkbenchDividerWidth,
          child: Stack(
            children: [
              if (collapseSide != null)
                Align(
                  alignment: collapseSide == HomeWorkbenchCollapseSide.workbench
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: kHomeWorkbenchDividerWidth / 2,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.horizontal(
                        left: collapseSide == HomeWorkbenchCollapseSide.workbench
                            ? const Radius.circular(999)
                            : Radius.zero,
                        right: collapseSide == HomeWorkbenchCollapseSide.logs
                            ? const Radius.circular(999)
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: collapseSide == null
                        ? dividerColor
                        : Colors.blueAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

