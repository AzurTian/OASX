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

  final logs = <String>[].obs;

  final archivedLogs = <String>[].obs;

  final autoScroll = true.obs;

  final collapseLog = false.obs;

  final _pendingLogs = <String>[];

  final Map<String, double> _savedScrollOffsets = <String, double>{};

  Timer? _refreshTimer;

  double _savedScrollOffset = 0.0;

  void Function({bool isJump, bool force, int scrollOffset})? scrollLogs;

  @override
  void onInit() {
    _refreshTimer ??= Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_pendingLogs.isEmpty) {
        return;
      }
      _clearOverflowLogs();
      _updateUILogs();
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

  void _updateUILogs() {
    final backlog = _pendingLogs.length;
    final burst = backlog.clamp(minBurst, maxBurst);
    for (int i = 0; i < burst && _pendingLogs.isNotEmpty; i++) {
      final nextLog = _pendingLogs.removeAt(0);
      logs.add(nextLog);
      archivedLogs.add(nextLog);
    }
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
