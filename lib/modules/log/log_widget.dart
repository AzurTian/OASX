import 'dart:math';

import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

import 'log_mixin.dart';

part 'log_widget_scroll.dart';
part 'log_widget_top_panel.dart';
part 'log_widget_content.dart';

class LogWidget extends StatefulWidget {
  const LogWidget({
    super.key,
    required this.controller,
    required this.title,
    this.enableCopy,
    this.enableAutoScroll,
    this.enableClear,
    this.enableCollapse,
    this.topPanelBottomChild,
  });

  final LogMixin controller;
  final String title;
  final bool? enableCopy;
  final bool? enableAutoScroll;
  final bool? enableClear;
  final bool? enableCollapse;
  final Widget? topPanelBottomChild;

  @override
  State<StatefulWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController ??= ScrollController(
      initialScrollOffset: widget.controller.savedScrollOffsetVal,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.autoScroll.value) {
        _scrollLogs(force: true, scrollOffset: -1);
      } else if (widget.controller.savedScrollOffsetVal > 0) {
        _scrollLogs(
          force: true,
          scrollOffset: widget.controller.savedScrollOffsetVal,
        );
      }
    });
    widget.controller.scrollLogs = _scrollLogs;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopLogPanel(
          title: widget.title,
          controller: widget.controller,
          enableCopy: widget.enableCopy,
          enableAutoScroll: widget.enableAutoScroll,
          enableClear: widget.enableClear,
          enableCollapse: widget.enableCollapse,
          bottomChild: widget.topPanelBottomChild,
        ),
        Obx(() => widget.controller.collapseLog.value
            ? const SizedBox.shrink()
            : LogContent(
                controller: widget.controller,
                scrollController: _scrollController!,
                onUserScroll: _handleUserScroll,
              ).expanded()),
      ],
    );
  }

  @override
  void deactivate() {
    if (_scrollController != null && _scrollController!.hasClients) {
      widget.controller.saveScrollOffset(_scrollController!.offset);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (_scrollController != null && _scrollController!.hasClients) {
      widget.controller.saveScrollOffset(_scrollController!.offset);
    }
    _scrollController?.dispose();
    _scrollController = null;
    super.dispose();
  }
}
