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
    required this.sidebar,
  });

  /// Home dashboard controller providing persisted split state.
  final HomeDashboardController controller;

  /// Builds the script collection pane for the resolved layout.
  final Widget Function(HomeWorkbenchLayoutMode layoutMode) collectionBuilder;

  /// Builds the active workbench pane for the resolved layout.
  final Widget Function(HomeWorkbenchLayoutMode layoutMode) detailsBuilder;

  /// Right sidebar widget reused in three-pane mode.
  final Widget sidebar;

  @override
  State<HomeWorkbenchBody> createState() => _HomeWorkbenchBodyState();
}

class _HomeWorkbenchBodyState extends State<HomeWorkbenchBody> {
  /// Tracks whether drag collapse has temporarily merged the log pane.
  bool _forceTwoPane = false;

  /// Remembers the width at which the right-side collapse was committed.
  double? _forcedTwoPaneWidth;

  /// Remembers the collection width at which the right-side collapse was committed.
  double? _forcedTwoPaneCollectionWidth;

  /// Tracks whether the left divider is actively dragging.
  bool _isDraggingLeftDivider = false;

  /// Remembers the latest width resolved by the current layout pass.
  double? _lastResolvedWidth;

  /// Remembers the latest collection width resolved by the current layout pass.
  double? _lastResolvedCollectionWidth;

  /// Stores a live collection width while the left divider is actively dragging.
  double? _dragCollectionWidth;

  /// Stores the raw collection width target while the left divider is dragging.
  double? _dragTargetCollectionWidth;

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
      final persistedCollectionWidth =
          widget.controller.workbenchCollectionWidth.value;
      final persistedSplitRatio = widget.controller.workbenchSplitRatio.value;
      return LayoutBuilder(
        builder: (context, constraints) {
          final unrestrictedLayout = resolveHomeWorkbenchLayout(
            maxWidth: constraints.maxWidth,
            collectionWidth: persistedCollectionWidth,
            splitRatio: persistedSplitRatio,
          );
          final layout = _resolveLayout(
            maxWidth: constraints.maxWidth,
            persistedCollectionWidth: persistedCollectionWidth,
            persistedSplitRatio: persistedSplitRatio,
            unrestrictedLayout: unrestrictedLayout,
          );
          final layoutMode = layout.mode;
          widget.controller.setWorkbenchLayoutMode(layoutMode);
          final collection = widget.collectionBuilder(layoutMode);
          final details = _buildPaneFrame(
            child: widget.detailsBuilder(layoutMode),
            highlighted:
                _pendingCollapseSide == HomeWorkbenchCollapseSide.workbench,
            progress: _pendingCollapseProgress,
          );
          final canExpandRightSidebar = _forceTwoPane &&
              unrestrictedLayout.mode == HomeWorkbenchLayoutMode.threePane;
          if (layoutMode == HomeWorkbenchLayoutMode.threePane) {
            return Row(
              key: const ValueKey<String>('home-workbench-three-pane'),
              children: [
                SizedBox(width: layout.collectionWidth, child: collection),
                _WorkbenchDivider(
                  key: const ValueKey<String>('home-workbench-left-divider'),
                  onDragStart: () => _handleLeftDragStart(layout),
                  onDragUpdate: (details) =>
                      _handleLeftDragUpdate(details, layout),
                  onDragEnd: _handleLeftDragEnd,
                  collapseSide: null,
                  collapseProgress: 0,
                ),
                SizedBox(width: layout.detailsWidth, child: details),
                _WorkbenchDivider(
                  key: const ValueKey<String>('home-workbench-right-divider'),
                  onDragStart: () => _handleRightDragStart(layout),
                  onDragUpdate: (details) =>
                      _handleRightDragUpdate(details, layout),
                  onDragEnd: _handleRightDragEnd,
                  collapseSide: _pendingCollapseSide,
                  collapseProgress: _pendingCollapseProgress,
                ),
                SizedBox(
                  width: layout.logWidth,
                  child: _buildPaneFrame(
                    child: widget.sidebar,
                    highlighted:
                        _pendingCollapseSide == HomeWorkbenchCollapseSide.logs,
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
                SizedBox(width: layout.collectionWidth, child: collection),
                _WorkbenchDivider(
                  key: const ValueKey<String>('home-workbench-left-divider'),
                  onDragStart: () => _handleLeftDragStart(layout),
                  onDragUpdate: (details) =>
                      _handleLeftDragUpdate(details, layout),
                  onDragEnd: _handleLeftDragEnd,
                  collapseSide: null,
                  collapseProgress: 0,
                ),
                SizedBox(
                  width: layout.detailsWidth,
                  child: _buildTwoPaneDetails(
                    details: details,
                    canExpandRightSidebar: canExpandRightSidebar,
                  ),
                ),
              ],
            );
          }
          return Obx(() {
            final showWorkspace = widget.controller.workbenchPage.value ==
                    HomeWorkbenchPage.workspace &&
                widget.controller.activeScriptName.value.trim().isNotEmpty;
            return showWorkspace ? details : collection;
          });
        },
      );
    });
  }

  /// Resolves the active layout and restores three-pane mode when legal again.
  HomeWorkbenchLayout _resolveLayout({
    required double maxWidth,
    required double persistedCollectionWidth,
    required double persistedSplitRatio,
    required HomeWorkbenchLayout unrestrictedLayout,
  }) {
    final currentCollectionWidth =
        _dragCollectionWidth ?? persistedCollectionWidth;
    final currentSplitRatio = _dragSplitRatio ?? persistedSplitRatio;
    _lastResolvedWidth = maxWidth;
    _lastResolvedCollectionWidth = currentCollectionWidth;
    _scheduleThreePaneRestoreIfNeeded(unrestrictedLayout.mode);
    return resolveHomeWorkbenchLayout(
      maxWidth: maxWidth,
      collectionWidth: currentCollectionWidth,
      splitRatio: currentSplitRatio,
      forceTwoPane: _forceTwoPane,
    );
  }

  /// Adds a restore action when the right sidebar was manually collapsed.
  Widget _buildTwoPaneDetails({
    required Widget details,
    required bool canExpandRightSidebar,
  }) {
    if (!canExpandRightSidebar) {
      return details;
    }
    return Stack(
      children: [
        Positioned.fill(child: details),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton.filledTonal(
            key: const ValueKey<String>('home-workbench-expand-right-sidebar'),
            onPressed: _handleRightSidebarExpand,
            icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
          ),
        ),
      ],
    );
  }

  /// Schedules three-pane restoration once the layout becomes legal again.
  void _scheduleThreePaneRestoreIfNeeded(
      HomeWorkbenchLayoutMode unrestrictedMode) {
    if (!_forceTwoPane ||
        _isDraggingLeftDivider ||
        !_hasRestoreTriggerChanged() ||
        unrestrictedMode != HomeWorkbenchLayoutMode.threePane) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_forceTwoPane ||
          _isDraggingLeftDivider ||
          !_hasRestoreTriggerChanged()) {
        return;
      }
      setState(() {
        _forceTwoPane = false;
        _forcedTwoPaneWidth = null;
        _forcedTwoPaneCollectionWidth = null;
      });
    });
  }

  /// Returns whether width or left-divider changes should restore three panes.
  bool _hasRestoreTriggerChanged() {
    final forcedWidth = _forcedTwoPaneWidth;
    final forcedCollectionWidth = _forcedTwoPaneCollectionWidth;
    final lastResolvedWidth = _lastResolvedWidth;
    final lastResolvedCollectionWidth = _lastResolvedCollectionWidth;
    if (forcedWidth == null ||
        forcedCollectionWidth == null ||
        lastResolvedWidth == null ||
        lastResolvedCollectionWidth == null) {
      return false;
    }
    final widthChanged = (lastResolvedWidth - forcedWidth).abs() > 0.5;
    final collectionChanged =
        (lastResolvedCollectionWidth - forcedCollectionWidth).abs() > 0.5;
    return widthChanged || collectionChanged;
  }

  /// Starts tracking left-divider movement from the current desktop width.
  void _handleLeftDragStart(HomeWorkbenchLayout layout) {
    _isDraggingLeftDivider = true;
    _dragCollectionWidth = layout.collectionWidth;
    _dragTargetCollectionWidth = layout.collectionWidth;
  }

  /// Updates the live collection width while keeping at least a two-pane desktop.
  void _handleLeftDragUpdate(
      DragUpdateDetails details, HomeWorkbenchLayout layout) {
    final currentTargetWidth =
        _dragTargetCollectionWidth ?? layout.collectionWidth;
    final nextTargetWidth = currentTargetWidth + details.delta.dx;
    final nextCollectionWidth = clampHomeWorkbenchCollectionWidth(
      layout: layout,
      targetCollectionWidth: nextTargetWidth,
    );
    setState(() {
      _dragTargetCollectionWidth = nextTargetWidth;
      _dragCollectionWidth = nextCollectionWidth;
    });
  }

  /// Persists the last valid collection width after dragging the left divider.
  void _handleLeftDragEnd(DragEndDetails details) {
    if (!mounted) {
      return;
    }
    final dragCollectionWidth = _dragCollectionWidth;
    if (dragCollectionWidth != null) {
      widget.controller.setWorkbenchCollectionWidth(dragCollectionWidth);
    }
    setState(() {
      _isDraggingLeftDivider = false;
      _dragCollectionWidth = null;
      _dragTargetCollectionWidth = null;
    });
  }

  /// Starts tracking right-divider movement from the current three-pane width.
  void _handleRightDragStart(HomeWorkbenchLayout layout) {
    _dragSplitRatio = layout.appliedSplitRatio;
    _dragTargetDetailsWidth = layout.detailsWidth;
    _pendingCollapseSide = null;
    _pendingCollapseProgress = 0;
    _collapseOnRelease = false;
  }

  /// Updates the live split ratio while exposing a buffered collapse state.
  void _handleRightDragUpdate(
      DragUpdateDetails details, HomeWorkbenchLayout layout) {
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
  void _handleRightDragEnd(DragEndDetails details) {
    if (!mounted) {
      return;
    }
    final dragSplitRatio = _dragSplitRatio;
    final collapseSide = _pendingCollapseSide;
    if (dragSplitRatio != null) {
      widget.controller.setWorkbenchSplitRatio(dragSplitRatio);
    }
    if (_collapseOnRelease && collapseSide != null) {
      final preservedTab = switch (collapseSide) {
        HomeWorkbenchCollapseSide.workbench =>
          widget.controller.displayedWorkbenchSidebarTabFor(
            HomeWorkbenchLayoutMode.threePane,
          ),
        HomeWorkbenchCollapseSide.logs => widget.controller
            .displayedWorkbenchTabFor(HomeWorkbenchLayoutMode.threePane),
      };
      widget.controller.setActiveWorkbenchTabValue(preservedTab);
    }
    setState(() {
      _forceTwoPane = _collapseOnRelease;
      _forcedTwoPaneWidth = _collapseOnRelease ? _lastResolvedWidth : null;
      _forcedTwoPaneCollectionWidth =
          _collapseOnRelease ? _lastResolvedCollectionWidth : null;
      _dragSplitRatio = null;
      _dragTargetDetailsWidth = null;
      _pendingCollapseSide = null;
      _pendingCollapseProgress = 0;
      _collapseOnRelease = false;
    });
  }

  /// Restores the desktop right sidebar without changing window width.
  void _handleRightSidebarExpand() {
    if (!_forceTwoPane || !mounted) {
      return;
    }
    setState(() {
      _forceTwoPane = false;
      _forcedTwoPaneWidth = null;
      _forcedTwoPaneCollectionWidth = null;
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
    super.key,
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
                        left:
                            collapseSide == HomeWorkbenchCollapseSide.workbench
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
                    color:
                        collapseSide == null ? dividerColor : Colors.blueAccent,
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
