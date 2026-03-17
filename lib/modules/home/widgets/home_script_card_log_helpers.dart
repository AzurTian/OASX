part of 'home_script_card.dart';

/// Matches timestamp segments in log lines with leading/trailing pipes.
final RegExp _homeScriptCardLogTimePipePattern =
    RegExp(r' \|\s*\d{2}:\d{2}:\d{2}\.\d{3}\s*\| ');

extension _HomeScriptCardLogHelpers on _HomeScriptCardLogViewState {
  /// Builds the log list view without the control header.
  Widget _buildLogList(BuildContext context) {
    final controller = _scrollController;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      if (_logController.logs.isEmpty) {
        return _buildEmptyLogState(context);
      }
      return NotificationListener<UserScrollNotification>(
        onNotification: (_) {
          _handleUserScroll();
          return false;
        },
        child: ListView.builder(
          controller: controller,
          primary: false,
          padding: EdgeInsets.zero,
          itemCount: _logController.logs.length,
          itemBuilder: (context, index) {
            final text = _stripLogTimestamp(_logController.logs[index]);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: EasyRichText(
                text,
                patternList: _homeScriptCardLogPatterns,
                selectable: false,
                defaultStyle: _selectStyle(context),
              ),
            );
          },
        ),
      );
    });
  }

  /// Builds the empty log placeholder state.
  Widget _buildEmptyLogState(BuildContext context) {
    return Center(
      child: Text(
        I18n.homeNoLog.tr,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  /// Removes timestamp segments from a log line for display.
  String _stripLogTimestamp(String raw) {
    var cleaned = raw.replaceAll(_homeScriptCardLogTimePipePattern, ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\|\s*\|'), ' ');
    return cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trimLeft();
  }

  /// Restores the initial scroll position based on controller state.
  void _restoreInitialScroll() {
    if (_logController.autoScroll.value) {
      _scrollLogs(force: true, scrollOffset: -1);
      return;
    }
    if (_logController.savedScrollOffsetVal > 0) {
      _scrollLogs(
        force: true,
        scrollOffset: _logController.savedScrollOffsetVal.toInt(),
      );
    }
  }

  /// Scrolls the log list to the requested position.
  void _scrollLogs({
    bool isJump = false,
    bool force = false,
    int scrollOffset = -1,
  }) {
    if (_scrollController == null || !_scrollController!.hasClients) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController == null || !_scrollController!.hasClients) {
        return;
      }
      if (!force && !_logController.autoScroll.value) {
        return;
      }
      final double targetPos = scrollOffset == -1
          ? _scrollController!.position.maxScrollExtent
          : scrollOffset.toDouble();
      if (isJump) {
        _scrollController!.jumpTo(targetPos);
        return;
      }
      final double currentPos = _scrollController!.offset;
      final double distance = (targetPos - currentPos).abs();
      int animateMs = (math.sqrt(distance) * 10).toInt();
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
        if (_scrollController == null || !_scrollController!.hasClients) {
          return;
        }
        final latestExtent = _scrollController!.position.maxScrollExtent;
        if ((scrollOffset == -1 || _logController.autoScroll.value) &&
            latestExtent > targetPos) {
          _scrollController!.jumpTo(latestExtent);
        }
      });
    });
  }

  /// Updates auto-scroll state based on user scroll position.
  void _handleUserScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) {
      return;
    }
    final maxExtent = _scrollController!.position.maxScrollExtent;
    final currentOffset = _scrollController!.offset;
    final isAtBottom = currentOffset >= (maxExtent - 80);

    if (isAtBottom && !_logController.autoScroll.value) {
      _logController.autoScroll.value = true;
    } else if (!isAtBottom && _logController.autoScroll.value) {
      _logController.autoScroll.value = false;
    }
  }

  /// Persists the scroll offset for the current controller.
  void _saveScrollOffset() {
    if (_scrollController != null && _scrollController!.hasClients) {
      _logController.saveScrollOffset(_scrollController!.offset);
    }
  }

  /// Ensures a log controller exists so logs are collected for the script.
  OverviewController _getOrCreateLogController(String name) {
    if (Get.isRegistered<OverviewController>(tag: name)) {
      return Get.find<OverviewController>(tag: name);
    }
    return Get.put(
      OverviewController(name: name),
      tag: name,
      permanent: true,
    );
  }

  /// Selects a default text style based on orientation.
  TextStyle _selectStyle(BuildContext context) {
    return context.mediaQuery.orientation == Orientation.portrait
        ? Theme.of(context).textTheme.bodySmall!
        : Theme.of(context).textTheme.titleSmall!;
  }
}
