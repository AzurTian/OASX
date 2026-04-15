import 'package:flutter/material.dart';

const _kSplitScrollRowBackgroundKey =
    ValueKey<String>('home-split-scroll-row-background');

class SplitScrollRow extends StatefulWidget {
  const SplitScrollRow({
    super.key,
    required this.leading,
    required this.trailing,
    required this.trailingExtent,
    required this.trailingBackgroundColor,
    this.minHeight = 0,
    this.trailingPadding = EdgeInsets.zero,
    this.scrollKey,
    this.scrollbarThickness = 4,
    this.scrollbarSpacing = 4,
  });

  final Widget leading;
  final Widget trailing;
  final double trailingExtent;
  final Color trailingBackgroundColor;
  final double minHeight;
  final EdgeInsetsGeometry trailingPadding;
  final Key? scrollKey;
  final double scrollbarThickness;
  final double scrollbarSpacing;

  @override
  State<SplitScrollRow> createState() => _SplitScrollRowState();
}

class _SplitScrollRowState extends State<SplitScrollRow> {
  final ScrollController _scrollController = ScrollController();
  bool _showsScrollbar = false;
  bool _syncQueued = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _queueOverflowSync();
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                _buildScrollBody(constraints.maxWidth),
                _buildTrailingOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollBody(double viewportWidth) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: _showsScrollbar,
      trackVisibility: false,
      interactive: false,
      thickness: widget.scrollbarThickness,
      radius: const Radius.circular(999),
      notificationPredicate: (notification) => notification.depth == 0,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _handleMetricsChanged,
        child: SingleChildScrollView(
          key: widget.scrollKey,
          controller: _scrollController,
          primary: false,
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: viewportWidth),
            child: Padding(
              padding: EdgeInsets.only(right: widget.trailingExtent),
              child: Align(
                alignment: Alignment.centerLeft,
                child: widget.leading,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingOverlay() {
    final backgroundBottomInset = _showsScrollbar
        ? widget.scrollbarThickness + widget.scrollbarSpacing
        : 0.0;
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: widget.trailingExtent,
      child: Stack(
        children: [
          if (_showsScrollbar)
            Positioned(
              key: _kSplitScrollRowBackgroundKey,
              top: 0,
              left: 0,
              right: 0,
              bottom: backgroundBottomInset,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(color: widget.trailingBackgroundColor),
              ),
            ),
          Padding(
            padding: widget.trailingPadding,
            child: Align(
              alignment: Alignment.centerRight,
              child: widget.trailing,
            ),
          ),
        ],
      ),
    );
  }

  bool _handleMetricsChanged(ScrollMetricsNotification notification) {
    _setScrollbarVisible(notification.metrics.maxScrollExtent > 0);
    return false;
  }

  void _queueOverflowSync() {
    if (_syncQueued) {
      return;
    }
    _syncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQueued = false;
      if (!mounted) {
        return;
      }
      final hasOverflow = _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0;
      _setScrollbarVisible(hasOverflow);
    });
  }

  void _setScrollbarVisible(bool visible) {
    if (_showsScrollbar == visible || !mounted) {
      return;
    }
    setState(() {
      _showsScrollbar = visible;
    });
  }
}
