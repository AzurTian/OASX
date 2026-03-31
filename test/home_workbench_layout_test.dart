import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';

void main() {
  group('resolveHomeWorkbenchLayout', () {
    test('restores the persisted split ratio in three-pane mode', () {
      final layout = resolveHomeWorkbenchLayout(
        maxWidth: 1200,
        splitRatio: 0.7,
      );

      expect(layout.mode, HomeWorkbenchLayoutMode.threePane);
      expect(layout.appliedSplitRatio, closeTo(0.7, 0.0001));
      expect(layout.detailsWidth, closeTo(layout.resizableWidth * 0.7, 0.0001));
      expect(layout.logWidth, closeTo(layout.resizableWidth * 0.3, 0.0001));
    });

    test('falls back to two panes when width cannot fit both detail minima', () {
      final layout = resolveHomeWorkbenchLayout(
        maxWidth: 1080,
        splitRatio: 0.5,
      );

      expect(layout.mode, HomeWorkbenchLayoutMode.twoPane);
    });

    test('falls back to a single pane when width cannot fit the list and workbench', () {
      final layout = resolveHomeWorkbenchLayout(
        maxWidth: 600,
        splitRatio: 0.5,
      );

      expect(layout.mode, HomeWorkbenchLayoutMode.singlePane);
    });

    test('sanitizes invalid persisted split values', () {
      expect(
        sanitizeHomeWorkbenchSplitRatio('invalid'),
        kHomeWorkbenchDefaultSplitRatio,
      );
      expect(sanitizeHomeWorkbenchSplitRatio(2), 1);
      expect(sanitizeHomeWorkbenchSplitRatio(-1), 0);
    });
  });

  group('resolveHomeWorkbenchTabs', () {
    test('keeps logs as a workspace tab outside three-pane mode', () {
      final threePaneTabs =
          resolveHomeWorkbenchTabs(HomeWorkbenchLayoutMode.threePane);
      final twoPaneTabs = resolveHomeWorkbenchTabs(HomeWorkbenchLayoutMode.twoPane);
      final singlePaneTabs =
          resolveHomeWorkbenchTabs(HomeWorkbenchLayoutMode.singlePane);

      expect(threePaneTabs, isNot(contains(HomeWorkbenchTab.logs)));
      expect(twoPaneTabs, contains(HomeWorkbenchTab.logs));
      expect(singlePaneTabs, contains(HomeWorkbenchTab.logs));
    });
  });

  group('resolveHomeWorkbenchDragState', () {
    final layout = resolveHomeWorkbenchLayout(
      maxWidth: 1200,
      splitRatio: 0.5,
    );

    test('locks at the minimum width and highlights the workbench first', () {
      final dragState = resolveHomeWorkbenchDragState(
        layout: layout,
        targetDetailsWidth: kHomeWorkbenchMinDetailsWidth - 40,
      );

      expect(dragState.detailsWidth, kHomeWorkbenchMinDetailsWidth);
      expect(dragState.collapseSide, HomeWorkbenchCollapseSide.workbench);
      expect(dragState.shouldCollapseOnRelease, isFalse);
    });

    test('commits collapse only after dragging across the full workbench buffer', () {
      final dragState = resolveHomeWorkbenchDragState(
        layout: layout,
        targetDetailsWidth: 0,
      );

      expect(dragState.collapseSide, HomeWorkbenchCollapseSide.workbench);
      expect(dragState.shouldCollapseOnRelease, isTrue);
    });

    test('locks at the minimum width and highlights the log pane first', () {
      final dragState = resolveHomeWorkbenchDragState(
        layout: layout,
        targetDetailsWidth: layout.resizableWidth - kHomeWorkbenchMinLogWidth + 40,
      );

      expect(dragState.logWidth, kHomeWorkbenchMinLogWidth);
      expect(dragState.collapseSide, HomeWorkbenchCollapseSide.logs);
      expect(dragState.shouldCollapseOnRelease, isFalse);
    });
  });
}

