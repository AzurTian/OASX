import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/widgets/home_split_scroll_row.dart';

const _backgroundKey = ValueKey<String>('home-split-scroll-row-background');

void main() {
  testWidgets('HomeSplitScrollRow hides scrollbar when content fits',
      (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        width: 360,
        child: HomeSplitScrollRow(
          trailingExtent: 56,
          trailingBackgroundColor: Colors.white,
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
          leading: const Text(
            'Short row',
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isFalse);
    expect(find.byKey(_backgroundKey), findsNothing);
  });

  testWidgets('HomeSplitScrollRow shows scrollbar and keeps actions fixed',
      (tester) async {
    var tapCount = 0;
    const scrollKey = ValueKey('overflow-scroll');
    const actionKey = ValueKey('fixed-action');

    await tester.pumpWidget(
      _buildHarness(
        width: 220,
        child: HomeSplitScrollRow(
          scrollKey: scrollKey,
          trailingExtent: 56,
          trailingBackgroundColor: Colors.white,
          trailing: IconButton(
            key: actionKey,
            onPressed: () => tapCount += 1,
            icon: const Icon(Icons.tune_rounded),
          ),
          leading: const Text(
            'This is a very long task name that must remain on one line',
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(scrollbar.thumbVisibility, isTrue);
    expect(find.byKey(_backgroundKey), findsOneWidget);

    final beforeDrag = tester.getCenter(find.byKey(actionKey));
    await tester.drag(find.byKey(scrollKey), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(tester.getCenter(find.byKey(actionKey)).dx,
        closeTo(beforeDrag.dx, 0.001));

    await tester.tap(find.byKey(actionKey));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('HomeSplitScrollRow lays out inside a vertical ListView',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              SizedBox(
                width: 220,
                child: HomeSplitScrollRow(
                  trailingExtent: 56,
                  trailingBackgroundColor: Colors.white,
                  trailing: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded),
                  ),
                  leading: const Text(
                    'This row must not crash when ListView gives it loose height',
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeSplitScrollRow respects minimum height for trailing actions',
      (tester) async {
    const rowKey = ValueKey('min-height-row');

    await tester.pumpWidget(
      _buildHarness(
        width: 220,
        child: HomeSplitScrollRow(
          key: rowKey,
          minHeight: 40,
          trailingExtent: 56,
          trailingBackgroundColor: Colors.white,
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
          leading: const Text(
            'Short',
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.getSize(find.byKey(rowKey)).height, greaterThanOrEqualTo(40));
  });

  testWidgets('HomeSplitScrollRow vertically centers leading content',
      (tester) async {
    const rowKey = ValueKey('centered-row');
    const leadingKey = ValueKey('centered-leading');

    await tester.pumpWidget(
      _buildHarness(
        width: 220,
        child: HomeSplitScrollRow(
          key: rowKey,
          minHeight: 40,
          trailingExtent: 56,
          trailingBackgroundColor: Colors.white,
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
          leading: const SizedBox(
            key: leadingKey,
            height: 20,
            width: 40,
            child: ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    );

    await tester.pump();

    final rowRect = tester.getRect(find.byKey(rowKey));
    final leadingRect = tester.getRect(find.byKey(leadingKey));
    final expectedTop = rowRect.top + ((rowRect.height - leadingRect.height) / 2);

    expect(leadingRect.top, closeTo(expectedTop, 0.001));
  });
}

Widget _buildHarness({
  required double width,
  required Widget child,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: child,
        ),
      ),
    ),
  );
}
