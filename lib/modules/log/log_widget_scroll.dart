part of 'log_widget.dart';

extension _LogWidgetScroll on _LogWidgetState {
  void _scrollLogs({isJump = false, force = false, scrollOffset = -1}) {
    if (_scrollController == null || !_scrollController!.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController == null || !_scrollController!.hasClients) return;
      if (!force && !widget.controller.autoScroll.value) return;
      final double targetPos = scrollOffset == -1
          ? _scrollController!.position.maxScrollExtent
          : scrollOffset;
      if (isJump) {
        _scrollController!.jumpTo(targetPos);
        return;
      }
      final double currentPos = _scrollController!.offset;
      final double distance = (targetPos - currentPos).abs();
      int animateMs = (sqrt(distance) * 10).toInt();
      const int minAnimateMs = 100;
      const int maxAnimateMs = 1000;
      animateMs = animateMs.clamp(minAnimateMs, maxAnimateMs);
      _scrollController!
          .animateTo(
        targetPos,
        duration: Duration(milliseconds: animateMs),
        curve: Curves.easeOut,
      )
          .whenComplete(() {
        if (_scrollController == null || !_scrollController!.hasClients) return;
        final latestExtent = _scrollController!.position.maxScrollExtent;
        if ((scrollOffset == -1 || widget.controller.autoScroll.value) &&
            latestExtent > targetPos) {
          _scrollController!.jumpTo(latestExtent);
        }
      });
    });
  }

  void _handleUserScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) return;
    final maxExtent = _scrollController!.position.maxScrollExtent;
    final currentOffset = _scrollController!.offset;
    final isAtBottom = currentOffset >= (maxExtent - 80);

    if (isAtBottom && !widget.controller.autoScroll.value) {
      widget.controller.autoScroll.value = true;
    } else if (!isAtBottom && widget.controller.autoScroll.value) {
      widget.controller.autoScroll.value = false;
    }
  }
}
