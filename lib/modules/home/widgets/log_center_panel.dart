import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/overview/index.dart';
import 'package:oasx/translation/i18n_content.dart';

class LogCenterPanel extends StatefulWidget {
  const LogCenterPanel({
    super.key,
    required this.scriptName,
  });

  final String scriptName;

  @override
  State<LogCenterPanel> createState() => _LogCenterPanelState();
}

class _LogCenterPanelState extends State<LogCenterPanel> {
  static final RegExp _logPattern = RegExp(
    r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) \|\s*([^|]+?)\s*\|\s*([A-Z]+)\s*\|\s*(.*)$',
  );
  static final RegExp _logLevelPattern = RegExp(
    r'(^|\|)\s*(INFO|WARNING|ERROR|CRITICAL)\s*(\||$)',
  );
  static const String _kScrollSlot = 'home-log-center';
  static const double _kAutoScrollAnchorOffset = 1000000000;
  static const double _kBottomThreshold = 80;

  OverviewController? _logController;
  ScrollController? _scrollController;
  String _level = 'ALL';

  @override
  void initState() {
    super.initState();
    _bindLogController(widget.scriptName);
  }

  @override
  void didUpdateWidget(covariant LogCenterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptName == widget.scriptName) {
      return;
    }
    _saveScrollOffset();
    _logController?.scrollLogs = null;
    _bindLogController(widget.scriptName);
  }

  @override
  void deactivate() {
    _saveScrollOffset();
    super.deactivate();
  }

  @override
  void dispose() {
    _saveScrollOffset();
    _logController?.scrollLogs = null;
    _scrollController?.dispose();
    super.dispose();
  }

  void _bindLogController(String scriptName) {
    final previousScrollController = _scrollController;
    _logController = _controllerFor(scriptName);
    _scrollController = _buildScrollController(_logController);
    _logController?.scrollLogs = _scrollLogs;
    previousScrollController?.dispose();
  }

  ScrollController _buildScrollController(OverviewController? controller) {
    final initialOffset = controller == null
        ? 0.0
        : controller.autoScroll.value
            ? _kAutoScrollAnchorOffset
            : controller.savedScrollOffsetFor(_kScrollSlot);
    return ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scriptName.trim().isEmpty) {
      return Card(child: Center(child: Text(I18n.homeNoScriptSelected.tr)));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(context),
            const SizedBox(height: 12),
            Expanded(child: _buildLogView(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(I18n.log.tr, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: _level,
              initialValue: _level,
              onSelected: (value) => setState(() {
                _level = value;
              }),
              itemBuilder: (context) => const [
                PopupMenuItem<String>(value: 'ALL', child: Text('ALL')),
                PopupMenuItem<String>(value: 'INFO', child: Text('INFO')),
                PopupMenuItem<String>(value: 'WARNING', child: Text('WARNING')),
                PopupMenuItem<String>(value: 'ERROR', child: Text('ERROR')),
                PopupMenuItem<String>(value: 'CRITICAL', child: Text('CRITICAL')),
              ],
              icon: Icon(
                Icons.filter_list_rounded,
                color: _level == 'ALL'
                    ? null
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            Obx(() {
              final controller = _logController;
              final isEnabled = controller?.autoScroll.value ?? false;
              return IconButton(
                tooltip: I18n.homeLogAutoScroll.tr,
                onPressed: controller == null
                    ? null
                    : () => controller.toggleAutoScroll(),
                icon: Icon(
                  isEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                ),
              );
            }),
            IconButton(
              tooltip: I18n.copy.tr,
              onPressed: _copyVisibleLogs,
              icon: const Icon(Icons.content_copy_rounded),
            ),
            IconButton(
              tooltip: I18n.clearLog.tr,
              onPressed: _clearLogs,
              icon: const Icon(Icons.delete_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogView(BuildContext context) {
    return Obx(() {
      final controller = _logController;
      final scrollController = _scrollController;
      if (controller == null || scrollController == null) {
        return Center(child: Text(I18n.homeNoLog.tr));
      }
      final sourceLogs = _sourceLogs(controller);
      if (sourceLogs.isEmpty) {
        return Center(child: Text(I18n.homeNoLog.tr));
      }
      final visibleLogs = sourceLogs.where(_matchesLevel).toList();
      if (visibleLogs.isEmpty) {
        return Center(child: Text(I18n.homeLogEmptyFiltered.tr));
      }
      final spans = _buildLogSpans(visibleLogs);
      if (spans.isEmpty) {
        return Center(child: Text(I18n.homeLogEmptyFiltered.tr));
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final text = _LogSelectableText(
            spans: spans,
            style: _defaultTextStyle(context),
          );
          return SelectionArea(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (_) {
                _handleUserScroll();
                return false;
              },
              child: SingleChildScrollView(
                key: ValueKey<String>('home-log-vertical-${widget.scriptName}'),
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: text,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  List<String> _sourceLogs(OverviewController controller) {
    return controller.logs.toList();
  }

  bool _matchesLevel(String raw) {
    if (_level == 'ALL') {
      return true;
    }
    final level = _parseEntry(raw).level;
    return level.isEmpty || level == _level;
  }

  _ParsedEntry _parseEntry(String raw) {
    final match = _logPattern.firstMatch(raw);
    if (match == null) {
      final levelMatch = _logLevelPattern.firstMatch(raw);
      return _ParsedEntry(level: levelMatch?.group(2) ?? '');
    }
    return _ParsedEntry(
      level: (match.group(3) ?? '').trim(),
    );
  }

  List<InlineSpan> _buildLogSpans(List<String> rawLogs) {
    final spans = <InlineSpan>[];
    for (var index = 0; index < rawLogs.length; index++) {
      spans.addAll(_buildHighlightedLine(_normalizeLogLine(rawLogs[index])));
      if (index < rawLogs.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return spans;
  }

  List<InlineSpan> _buildHighlightedLine(String raw) {
    final spans = <InlineSpan>[];
    final patterns = _highlightPatterns();
    var cursor = 0;
    while (cursor < raw.length) {
      _LogHighlightMatch? match;
      for (final pattern in patterns) {
        final currentMatch = pattern.expression.matchAsPrefix(raw, cursor);
        if (currentMatch == null) {
          continue;
        }
        match = _LogHighlightMatch(
          start: currentMatch.start,
          end: currentMatch.end,
          style: pattern.style,
        );
        break;
      }
      if (match == null) {
        final nextCursor = _nextCodePointBoundary(raw, cursor);
        spans.add(TextSpan(text: raw.substring(cursor, nextCursor)));
        cursor = nextCursor;
        continue;
      }
      spans.add(TextSpan(
        text: raw.substring(match.start, match.end),
        style: match.style,
      ));
      cursor = match.end;
    }
    return spans;
  }

  List<_LogHighlightPattern> _highlightPatterns() {
    return [
      _LogHighlightPattern(
        expression: RegExp(r'\d{2}:\d{2}:\d{2}\.\d{3}'),
        style: const TextStyle(
          color: Colors.cyan,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'INFO'),
        style: const TextStyle(
          color: Color.fromARGB(255, 55, 109, 136),
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'WARNING'),
        style: const TextStyle(
          color: Colors.yellow,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'ERROR|CRITICAL'),
        style: const TextStyle(
          color: Colors.red,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'[\[\]【】]'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'[\{\(\)\}]'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'True'),
        style: const TextStyle(color: Colors.lightGreen),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'False'),
        style: const TextStyle(color: Colors.red),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'None'),
        style: const TextStyle(color: Colors.purple),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'[═─]{5,}'),
        style: const TextStyle(color: Colors.lightGreen),
      ),
      _LogHighlightPattern(
        expression: RegExp(r'<<<.*?>>>'),
        style: const TextStyle(color: Colors.lightGreen),
      ),
    ];
  }

  String _normalizeLogLine(String raw) {
    final trimmed = raw.replaceAll(RegExp(r'[\r\n]+$'), '');
    return _sanitizeUtf16(trimmed);
  }

  int _nextCodePointBoundary(String value, int start) {
    if (start >= value.length) {
      return value.length;
    }
    final current = value.codeUnitAt(start);
    if (_isHighSurrogate(current) && start + 1 < value.length) {
      final next = value.codeUnitAt(start + 1);
      if (_isLowSurrogate(next)) {
        return start + 2;
      }
    }
    return start + 1;
  }

  String _sanitizeUtf16(String value) {
    final buffer = StringBuffer();
    var index = 0;
    while (index < value.length) {
      final current = value.codeUnitAt(index);
      if (_isHighSurrogate(current)) {
        if (index + 1 < value.length) {
          final next = value.codeUnitAt(index + 1);
          if (_isLowSurrogate(next)) {
            buffer.writeCharCode(current);
            buffer.writeCharCode(next);
            index += 2;
            continue;
          }
        }
        buffer.writeCharCode(0xFFFD);
        index++;
        continue;
      }
      if (_isLowSurrogate(current)) {
        buffer.writeCharCode(0xFFFD);
        index++;
        continue;
      }
      buffer.writeCharCode(current);
      index++;
    }
    return buffer.toString();
  }

  bool _isHighSurrogate(int value) {
    return value >= 0xD800 && value <= 0xDBFF;
  }

  bool _isLowSurrogate(int value) {
    return value >= 0xDC00 && value <= 0xDFFF;
  }

  void _copyVisibleLogs() {
    final controller = _logController;
    if (controller == null) {
      return;
    }
    final visibleLogs = _sourceLogs(controller)
        .where(_matchesLevel)
        .map(_normalizeLogLine)
        .join('\n');
    Clipboard.setData(ClipboardData(text: visibleLogs));
    Get.snackbar(
      I18n.tip.tr,
      I18n.copySuccess.tr,
      duration: const Duration(seconds: 1),
    );
  }

  void _clearLogs() {
    final controller = _logController;
    if (controller == null) {
      return;
    }
    controller.clearLog();
    controller.saveScrollOffsetFor(_kScrollSlot, 0);
    final scrollController = _scrollController;
    if (scrollController != null && scrollController.hasClients) {
      controller.autoScroll.value = true;
    }
  }

  TextStyle _defaultTextStyle(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return baseStyle.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.4,
    );
  }

  OverviewController _resolveController(String scriptName) {
    if (Get.isRegistered<OverviewController>(tag: scriptName)) {
      return Get.find<OverviewController>(tag: scriptName);
    }
    return Get.put(
      OverviewController(name: scriptName),
      tag: scriptName,
      permanent: true,
    );
  }

  OverviewController? _controllerFor(String scriptName) {
    final normalized = scriptName.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return _resolveController(normalized);
  }

  void _scrollLogs({
    bool isJump = false,
    bool force = false,
    int scrollOffset = -1,
  }) {
    final controller = _logController;
    final scrollController = _scrollController;
    if (controller == null || scrollController == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) {
        return;
      }
      if (!force && !controller.autoScroll.value) {
        return;
      }
      final maxExtent = scrollController.position.maxScrollExtent;
      final targetOffset = scrollOffset == -1
          ? maxExtent
          : scrollOffset.toDouble().clamp(0.0, maxExtent).toDouble();
      final distance = (targetOffset - scrollController.offset).abs();
      if (distance < 1) {
        return;
      }
      final durationMs = (distance / 2).clamp(120, 800).toInt();
      scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleUserScroll() {
    final controller = _logController;
    final scrollController = _scrollController;
    if (controller == null || scrollController == null) {
      return;
    }
    if (!scrollController.hasClients) {
      return;
    }
    final maxExtent = scrollController.position.maxScrollExtent;
    final offset = scrollController.offset;
    final isAtBottom = offset >= maxExtent - _kBottomThreshold;
    controller.saveScrollOffsetFor(_kScrollSlot, offset);
    if (isAtBottom && !controller.autoScroll.value) {
      controller.autoScroll.value = true;
    } else if (!isAtBottom && controller.autoScroll.value) {
      controller.autoScroll.value = false;
    }
  }

  void _saveScrollOffset() {
    final controller = _logController;
    final scrollController = _scrollController;
    if (controller == null || scrollController == null) {
      return;
    }
    if (scrollController.hasClients) {
      controller.saveScrollOffsetFor(_kScrollSlot, scrollController.offset);
    }
  }
}

class _LogSelectableText extends StatelessWidget {
  const _LogSelectableText({
    required this.spans,
    required this.style,
  });

  final List<InlineSpan> spans;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(style: style, children: spans),
      softWrap: true,
      selectionRegistrar: SelectionContainer.maybeOf(context),
      selectionColor: Theme.of(context)
          .colorScheme
          .secondaryContainer
          .withValues(alpha: 0.35),
    );
  }
}

class _ParsedEntry {
  const _ParsedEntry({
    this.level = '',
  });

  final String level;
}

class _LogHighlightPattern {
  const _LogHighlightPattern({
    required this.expression,
    required this.style,
  });

  final RegExp expression;
  final TextStyle style;
}

class _LogHighlightMatch {
  const _LogHighlightMatch({
    required this.start,
    required this.end,
    required this.style,
  });

  final int start;
  final int end;
  final TextStyle style;
}
