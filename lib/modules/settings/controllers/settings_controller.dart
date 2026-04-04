import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/global.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/utils/platform_utils.dart';

class SettingsController extends GetxController {
  final storage = GetStorage();

  late String temporaryDirectory;
  final autoLoginAfterDeploy = false.obs;
  final autoDeploy = false.obs;
  bool _loginConfigChanged = false;

  final address = ''.obs;
  final username = ''.obs;
  final password = ''.obs;

  @override
  void onInit() {
    autoLoginAfterDeploy.value =
        storage.read(StorageKey.autoLoginAfterDeploy.name) ?? false;
    autoDeploy.value = (storage.read(StorageKey.autoDeploy.name) ?? false) &&
        PlatformUtils.isDesktop;
    address.value = storage.read(StorageKey.address.name) ?? '';
    username.value = storage.read(StorageKey.username.name) ?? '';
    password.value = storage.read(StorageKey.password.name) ?? '';

    initTemporaryDirectory();
    getCurrentVersion().then((value) {
      GlobalVar.version = value;
    });
    _syncApiAddress();
    super.onInit();
  }

  void initTemporaryDirectory() {
    final cachedDirectory = storage.read(StorageKey.temporaryDirectory.name);
    if (cachedDirectory is String && cachedDirectory.isNotEmpty) {
      temporaryDirectory = cachedDirectory;
      return;
    }

    temporaryDirectory = kIsWeb ? 'web_cache' : Directory.systemTemp.path;
    storage.write(StorageKey.temporaryDirectory.name, temporaryDirectory);
  }

  void updateAutoLoginAfterDeploy(bool nv) {
    autoLoginAfterDeploy.value = nv;
    storage.write(StorageKey.autoLoginAfterDeploy.name, nv);
  }

  void updateAutoDeploy(bool nv) {
    autoDeploy.value = nv;
    storage.write(StorageKey.autoDeploy.name, nv);
  }

  void updateAddress(String value) {
    final next = value.trim();
    if (address.value == next) {
      return;
    }
    address.value = next;
    storage.write(StorageKey.address.name, address.value);
    _syncApiAddress();
    _loginConfigChanged = true;
  }

  void updateUsername(String value) {
    final next = value.trim();
    if (username.value == next) {
      return;
    }
    username.value = next;
    storage.write(StorageKey.username.name, username.value);
    _loginConfigChanged = true;
  }

  void updatePassword(String value) {
    if (password.value == value) {
      return;
    }
    password.value = value;
    storage.write(StorageKey.password.name, password.value);
    _loginConfigChanged = true;
  }

  bool consumeLoginConfigChanged() {
    final changed = _loginConfigChanged;
    _loginConfigChanged = false;
    return changed;
  }

  void _syncApiAddress() {
    if (address.value.isEmpty) {
      return;
    }
    final normalized = address.value.startsWith('http://') ||
            address.value.startsWith('https://')
        ? address.value
        : 'http://${address.value}';
    ApiClient().setAddress(normalized);
  }

  Future<bool> killServer({
    bool showTip = true,
    bool resetDashboardToDisconnected = true,
  }) async {
    final success = await ApiClient().killServer();
    if (success) {
      if (resetDashboardToDisconnected) {
        unawaited(_resetDashboardAfterKillServer());
      }
    } else if (showTip) {
      Get.snackbar(I18n.killServerFailure.tr, I18n.killServerFailureMsg.tr);
    }
    return success;
  }

  Future<void> _resetDashboardAfterKillServer() async {
    if (Get.isRegistered<HomeDashboardController>()) {
      Get.find<HomeDashboardController>().markConnectionFailedFromKillServer();
    }
    if (Get.isRegistered<ScriptService>()) {
      try {
        await Get.find<ScriptService>()
            .resetDashboardState()
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
  }
}
