import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/common/models/window_state.dart';
import 'package:oasx/service/system_tray_service.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxService with WindowListener {
  // ignore: unused_field
  final _storage = GetStorage();
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  bool _didInitDesktop = false;
  int _trayInitToken = 0;

  Timer? _debounceTimer;
  DateTime? _lastSaveTime;
  final enableWindowState = false.obs;
  final enableSystemTray = false.obs;

  @override
  Future<void> onInit() async {
    try {
      await _initDesktopIfNeeded();
    } catch (e) {
      printError(info: 'window init failed: $e');
    } finally {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
    super.onInit();
  }

  Future<void> _initDesktopIfNeeded() async {
    if (_didInitDesktop || !PlatformUtils.isDesktop) return;
    _didInitDesktop = true;

    await windowManager.ensureInitialized();

    enableWindowState.value =
        _storage.read(StorageKey.enableWindowState.name) ?? false;
    enableSystemTray.value =
        _storage.read(StorageKey.enableSystemTray.name) ?? false;

    final lastState = await initWindowState();

    await windowManager.waitUntilReadyToShow(buildWindowOptions(lastState));
    windowManager.addListener(this);

    _kickoffSystemTrayInit();
  }

  void _kickoffSystemTrayInit() {
    if (!PlatformUtils.isDesktop) return;

    if (!enableSystemTray.value) {
      unawaited(windowManager.setPreventClose(false));
      return;
    }

    // 托盘启用时，先保证可关闭；待托盘创建成功后再拦截关闭事件，避免开机登录时托盘未就绪导致“无法退出”。
    unawaited(windowManager.setPreventClose(false));

    final token = ++_trayInitToken;
    unawaited(_ensureSystemTrayReady(token));
  }

  Future<void> _ensureSystemTrayReady(int token) async {
    const maxAttempts = 30;
    const retryDelay = Duration(seconds: 1);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (!PlatformUtils.isDesktop) return;
      if (!enableSystemTray.value) return;
      if (token != _trayInitToken) return;

      final ok = await Get.find<SystemTrayService>().showTray();
      if (ok) {
        await windowManager.setPreventClose(true);
        return;
      }

      await Future.delayed(retryDelay);
    }

    printInfo(info: 'system tray init failed, allow window close.');
  }

  WindowOptions buildWindowOptions(WindowStateModel? lastState) {
    return WindowOptions(
      size: (lastState != null)
          ? Size(lastState.width, lastState.height)
          : const Size(1200, 800),
      center: lastState == null,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
  }

  Future<WindowStateModel?> initWindowState() async {
    if (!enableWindowState.value) return null;
    final jsonStr = _storage.read(StorageKey.windowState.name);
    if (jsonStr == null) return null;
    WindowStateModel? lastState =
        WindowStateModel.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
    await windowManager.setBounds(Rect.fromLTWH(
      lastState.x,
      lastState.y,
      lastState.width,
      lastState.height,
    ));
    return lastState;
  }

  Future<void> _saveWindowState() async {
    if (!PlatformUtils.isDesktop || !enableWindowState.value) return;
    final size = await windowManager.getSize();
    final pos = await windowManager.getPosition();
    final state = WindowStateModel(
      x: pos.dx,
      y: pos.dy,
      width: size.width,
      height: size.height,
    );
    _storage.write(StorageKey.windowState.name, json.encode(state.toJson()));
    printInfo(info: 'save window state:${state.toJson()}');
  }

  void _scheduleSave() {
    if (!PlatformUtils.isDesktop || !enableWindowState.value) return;
    final now = DateTime.now();
    if (_lastSaveTime == null ||
        now.difference(_lastSaveTime!) > const Duration(seconds: 2)) {
      _lastSaveTime = now;
      _saveWindowState();
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      _lastSaveTime = DateTime.now();
      await _saveWindowState();
    });
  }

  @override
  void onWindowMove() => _scheduleSave();
  @override
  void onWindowResize() => _scheduleSave();

  @override
  void onWindowClose() async {
    _debounceTimer?.cancel();
    final preventClose = await windowManager.isPreventClose();
    if (!preventClose) return;
    await _saveWindowState();
    // 检查是否已经设置了最小化到托盘的选项
    if (enableSystemTray.value) {
      await windowManager.hide();
      return;
    }
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  @override
  void onClose() {
    if (PlatformUtils.isDesktop) {
      windowManager.removeListener(this);
    }
    _debounceTimer?.cancel();
    super.onClose();
  }

  void updateWindowStateEnable(bool newVal) {
    enableWindowState.value = newVal;
    _storage.write(StorageKey.enableWindowState.name, newVal);
  }

  Future<void> updateSystemTrayEnable(bool newVal) async {
    enableSystemTray.value = newVal;
    _storage.write(StorageKey.enableSystemTray.name, newVal);

    if (!PlatformUtils.isDesktop) return;

    if (newVal) {
      _kickoffSystemTrayInit();
      return;
    }

    _trayInitToken++;
    await windowManager.setPreventClose(false);
    await Get.find<SystemTrayService>().hideTray();
  }
}
