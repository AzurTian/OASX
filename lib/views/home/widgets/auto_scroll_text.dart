import 'dart:math';

import 'package:flutter/material.dart';

class AutoScrollText extends StatefulWidget {
  const AutoScrollText({
    super.key,
    required this.text,
  });

  final String text;

  @override
  State<AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<AutoScrollText> {
  final ScrollController _scrollController = ScrollController();
  bool _loopRunning = false;

  @override
  void initState() {
    super.initState();
    _tryStartLoop();
  }

  @override
  void didUpdateWidget(covariant AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _tryStartLoop(reset: true);
    }
  }

  void _tryStartLoop({bool reset = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (reset) {
        _scrollController.jumpTo(0);
      }
      if (_scrollController.position.maxScrollExtent <= 0 || _loopRunning) {
        return;
      }

      _loopRunning = true;
      while (mounted &&
          _scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        final duration =
            Duration(milliseconds: max(1800, (maxExtent * 28).round()));
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted || !_scrollController.hasClients) {
          break;
        }
        await _scrollController.animateTo(
          maxExtent,
          duration: duration,
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted || !_scrollController.hasClients) {
          break;
        }
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
        );
      }
      _loopRunning = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge;
    final textHeight = (textStyle?.fontSize ?? 14) * (textStyle?.height ?? 1.3);
    return SizedBox(
      height: textHeight + 2,
      child: ListView(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: [
          Text(widget.text, style: textStyle),
        ],
      ),
    );
  }
}
