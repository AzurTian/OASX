import 'package:flutter/foundation.dart';

/// Defines the responsive layout mode for the home workbench.
enum HomeWorkbenchLayoutMode {
  threePane,
  twoPane,
  singlePane,
}

/// Gap between the script list and the details pane.
const double kHomeWorkbenchPaneGap = 12;

/// Fixed width for the script list pane.
const double kHomeWorkbenchScriptListWidth = 340;

/// Width reserved for the draggable divider hit area.
const double kHomeWorkbenchDividerWidth = 16;

/// Minimum width for the active workbench pane.
const double kHomeWorkbenchMinDetailsWidth = 360;

/// Minimum width for the log pane.
const double kHomeWorkbenchMinLogWidth = 360;

/// Default split ratio for the resizable detail region.
const double kHomeWorkbenchDefaultSplitRatio = 0.5;

/// Identifies which detail pane is pending collapse during divider drag.
enum HomeWorkbenchCollapseSide {
  workbench,
  logs,
}

/// Resolves invalid persisted values to a safe ratio.
double sanitizeHomeWorkbenchSplitRatio(dynamic rawValue) {
  final value = switch (rawValue) {
    num() => rawValue.toDouble(),
    String() => double.tryParse(rawValue),
    _ => null,
  };
  if (value == null || !value.isFinite) {
    return kHomeWorkbenchDefaultSplitRatio;
  }
  return value.clamp(0.0, 1.0).toDouble();
}

/// Calculates the active home workbench layout for the available width.
HomeWorkbenchLayout resolveHomeWorkbenchLayout({
  required double maxWidth,
  required double splitRatio,
  bool forceTwoPane = false,
}) {
  final width = maxWidth.isFinite ? maxWidth : 0.0;
  final normalizedSplitRatio = sanitizeHomeWorkbenchSplitRatio(splitRatio);
  const twoPaneThreshold = kHomeWorkbenchScriptListWidth +
      kHomeWorkbenchPaneGap +
      kHomeWorkbenchMinDetailsWidth;
  if (width < twoPaneThreshold) {
    return const HomeWorkbenchLayout.singlePane();
  }

  final resizableWidth = width -
      kHomeWorkbenchScriptListWidth -
      kHomeWorkbenchPaneGap -
      kHomeWorkbenchDividerWidth;
  final canShowThreePane = !forceTwoPane &&
      resizableWidth >=
          kHomeWorkbenchMinDetailsWidth + kHomeWorkbenchMinLogWidth;
  if (!canShowThreePane) {
    return const HomeWorkbenchLayout.twoPane();
  }

  final minSplitRatio = kHomeWorkbenchMinDetailsWidth / resizableWidth;
  final maxSplitRatio = 1 - (kHomeWorkbenchMinLogWidth / resizableWidth);
  final appliedSplitRatio =
      normalizedSplitRatio.clamp(minSplitRatio, maxSplitRatio).toDouble();
  final detailsWidth = resizableWidth * appliedSplitRatio;
  final logWidth = resizableWidth - detailsWidth;
  return HomeWorkbenchLayout.threePane(
    detailsWidth: detailsWidth,
    logWidth: logWidth,
    resizableWidth: resizableWidth,
    appliedSplitRatio: appliedSplitRatio,
    minSplitRatio: minSplitRatio,
    maxSplitRatio: maxSplitRatio,
  );
}

/// Describes the active home workbench layout and pane geometry.
@immutable
class HomeWorkbenchLayout {
  /// Creates a single-pane layout result.
  const HomeWorkbenchLayout.singlePane()
      : mode = HomeWorkbenchLayoutMode.singlePane,
        detailsWidth = 0,
        logWidth = 0,
        resizableWidth = 0,
        appliedSplitRatio = kHomeWorkbenchDefaultSplitRatio,
        minSplitRatio = 0,
        maxSplitRatio = 1;

  /// Creates a two-pane layout result.
  const HomeWorkbenchLayout.twoPane()
      : mode = HomeWorkbenchLayoutMode.twoPane,
        detailsWidth = 0,
        logWidth = 0,
        resizableWidth = 0,
        appliedSplitRatio = kHomeWorkbenchDefaultSplitRatio,
        minSplitRatio = 0,
        maxSplitRatio = 1;

  /// Creates a three-pane layout result.
  const HomeWorkbenchLayout.threePane({
    required this.detailsWidth,
    required this.logWidth,
    required this.resizableWidth,
    required this.appliedSplitRatio,
    required this.minSplitRatio,
    required this.maxSplitRatio,
  }) : mode = HomeWorkbenchLayoutMode.threePane;

  /// Active layout mode resolved from the current constraints.
  final HomeWorkbenchLayoutMode mode;

  /// Width of the workbench pane in three-pane mode.
  final double detailsWidth;

  /// Width of the log pane in three-pane mode.
  final double logWidth;

  /// Width of the resizable workbench plus log region.
  final double resizableWidth;

  /// Effective split ratio after clamping to valid bounds.
  final double appliedSplitRatio;

  /// Minimum legal split ratio for the current width.
  final double minSplitRatio;

  /// Maximum legal split ratio for the current width.
  final double maxSplitRatio;
}

/// Describes the divider drag state after clamping to the legal range.
@immutable
class HomeWorkbenchDragState {
  /// Creates a drag state snapshot for the current gesture position.
  const HomeWorkbenchDragState({
    required this.detailsWidth,
    required this.logWidth,
    required this.splitRatio,
    required this.collapseSide,
    required this.collapseProgress,
    required this.shouldCollapseOnRelease,
  });

  /// Width rendered for the workbench pane during the drag.
  final double detailsWidth;

  /// Width rendered for the log pane during the drag.
  final double logWidth;

  /// Ratio rendered for the divider during the drag.
  final double splitRatio;

  /// Side currently highlighted as a pending collapse target.
  final HomeWorkbenchCollapseSide? collapseSide;

  /// Normalized progress inside the pending collapse buffer.
  final double collapseProgress;

  /// Whether releasing now should commit the two-pane collapse.
  final bool shouldCollapseOnRelease;
}

/// Resolves the divider drag state, including pending collapse feedback.
HomeWorkbenchDragState resolveHomeWorkbenchDragState({
  required HomeWorkbenchLayout layout,
  required double targetDetailsWidth,
}) {
  final clampedDetailsWidth = targetDetailsWidth
      .clamp(kHomeWorkbenchMinDetailsWidth, layout.resizableWidth - kHomeWorkbenchMinLogWidth)
      .toDouble();
  final clampedLogWidth = layout.resizableWidth - clampedDetailsWidth;
  final splitRatio = clampedDetailsWidth / layout.resizableWidth;
  final leftOverflow = (kHomeWorkbenchMinDetailsWidth - targetDetailsWidth)
      .clamp(0.0, kHomeWorkbenchMinDetailsWidth)
      .toDouble();
  final rightOverflow =
      (targetDetailsWidth - (layout.resizableWidth - kHomeWorkbenchMinLogWidth))
          .clamp(0.0, kHomeWorkbenchMinLogWidth)
          .toDouble();
  if (leftOverflow > 0) {
    return HomeWorkbenchDragState(
      detailsWidth: clampedDetailsWidth,
      logWidth: clampedLogWidth,
      splitRatio: splitRatio,
      collapseSide: HomeWorkbenchCollapseSide.workbench,
      collapseProgress: leftOverflow / kHomeWorkbenchMinDetailsWidth,
      shouldCollapseOnRelease: leftOverflow >= kHomeWorkbenchMinDetailsWidth,
    );
  }
  if (rightOverflow > 0) {
    return HomeWorkbenchDragState(
      detailsWidth: clampedDetailsWidth,
      logWidth: clampedLogWidth,
      splitRatio: splitRatio,
      collapseSide: HomeWorkbenchCollapseSide.logs,
      collapseProgress: rightOverflow / kHomeWorkbenchMinLogWidth,
      shouldCollapseOnRelease: rightOverflow >= kHomeWorkbenchMinLogWidth,
    );
  }
  return HomeWorkbenchDragState(
    detailsWidth: clampedDetailsWidth,
    logWidth: clampedLogWidth,
    splitRatio: splitRatio,
    collapseSide: null,
    collapseProgress: 0,
    shouldCollapseOnRelease: false,
  );
}
