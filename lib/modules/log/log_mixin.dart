import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oasx/translation/i18n_content.dart';

mixin LogMixin on GetxController {
  int get maxLines => 200;

  int get maxBuffer => 1000;

  int get maxArchivedLines => 5000;

  int get maxBurst => 50;

  int get minBurst => 1;

  /// Controls the maximum UI refresh rate for log updates.
  Duration get uiRefreshInterval => const Duration(milliseconds: 120);

  final logs = <String>[].obs;

  final archivedLogs = <String>[].obs;

  final autoScroll = true.obs;

  final collapseLog = false.obs;

  final _pendingLogs = <String>[];

  final Map<String, double> _savedScrollOffsets = <String, double>{};

  Timer? _refreshTimer;

  double _savedScrollOffset = 0.0;

  /// Monotonic stopwatch for UI refresh throttling.
  final Stopwatch _uiRefreshWatch = Stopwatch();

  /// Tracks the last refresh tick in milliseconds.
  int _lastUiRefreshTick = 0;

  void Function({bool isJump, bool force, int scrollOffset})? scrollLogs;

  @override
  void onInit() {
    _uiRefreshWatch.start();
    _refreshTimer ??= Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_pendingLogs.isEmpty) {
        return;
      }
      final nowTick = _uiRefreshWatch.elapsedMilliseconds;
      if (nowTick - _lastUiRefreshTick < uiRefreshInterval.inMilliseconds) {
        _clearOverflowLogs();
        return;
      }
      _lastUiRefreshTick = nowTick;
      _clearOverflowLogs();
      final appended = _updateUILogs();
      if (appended == 0) {
        return;
      }
      _removeUIOldLogs();
      scrollLogs?.call();
    });
    super.onInit();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.onClose();
  }

  void _removeUIOldLogs() {
    if (!autoScroll.value) {
      return;
    }
    if (logs.length > maxLines) {
      logs.removeRange(0, logs.length - maxLines);
    }
    if (archivedLogs.length > maxArchivedLines) {
      archivedLogs.removeRange(0, archivedLogs.length - maxArchivedLines);
    }
  }

  /// Moves a batch of pending logs into the UI-facing collections.
  int _updateUILogs() {
    final backlog = _pendingLogs.length;
    final burst = backlog.clamp(minBurst, maxBurst);
    if (burst <= 0) {
      return 0;
    }
    final batch = _pendingLogs.take(burst).toList();
    if (batch.isEmpty) {
      return 0;
    }
    _pendingLogs.removeRange(0, batch.length);
    logs.addAll(batch);
    archivedLogs.addAll(batch);
    return batch.length;
  }

  /// Forces pending logs into the UI list to avoid empty views on switch.
  int flushPendingLogs({int? maxBatch}) {
    if (_pendingLogs.isEmpty) {
      return 0;
    }
    _clearOverflowLogs();
    final limit = maxBatch ?? _pendingLogs.length;
    final count = min(limit, _pendingLogs.length);
    if (count <= 0) {
      return 0;
    }
    final batch = _pendingLogs.take(count).toList();
    _pendingLogs.removeRange(0, count);
    logs.addAll(batch);
    archivedLogs.addAll(batch);
    _removeUIOldLogs();
    _lastUiRefreshTick = _uiRefreshWatch.elapsedMilliseconds;
    return count;
  }

  void _clearOverflowLogs() {
    var totalSize = logs.length + _pendingLogs.length;
    if (totalSize > maxBuffer) {
      var overflow = totalSize - maxBuffer;
      if (overflow > 0) {
        final removeFromLogs = min(overflow, logs.length);
        if (removeFromLogs > 0) {
          logs.removeRange(0, removeFromLogs);
          overflow -= removeFromLogs;
        }
      }
      if (overflow > 0 && _pendingLogs.isNotEmpty) {
        final removeFromPending = min(overflow, _pendingLogs.length);
        _pendingLogs.removeRange(0, removeFromPending);
      }
    }
  }

  void addLog(String log) {
    _pendingLogs.add(log);
  }

  void clearLog() {
    logs.clear();
    archivedLogs.clear();
    _pendingLogs.clear();
  }

  void copyLogs() {
    final allLogs = logs.join('');
    Clipboard.setData(ClipboardData(text: allLogs));
    Get.snackbar(
      I18n.tip.tr,
      I18n.copySuccess.tr,
      duration: const Duration(seconds: 1),
    );
  }

  void toggleAutoScroll() {
    autoScroll.value = !autoScroll.value;
    if (autoScroll.value) {
      scrollLogs?.call(force: true, scrollOffset: -1);
    }
  }

  void toggleCollapse() => collapseLog.value = !collapseLog.value;

  double get savedScrollOffsetVal => _savedScrollOffset;

  double savedScrollOffsetFor(String slot) {
    return _savedScrollOffsets[slot] ?? 0.0;
  }

  void saveScrollOffset(double offset) {
    _savedScrollOffset = offset;
  }

  void saveScrollOffsetFor(String slot, double offset) {
    _savedScrollOffsets[slot] = offset;
  }
}
