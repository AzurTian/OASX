import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/controller/settings.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/server/server_view.dart';

class HomeDashboardController extends GetxController {
  final _storage = GetStorage();
  static bool _hasCheckedStartupConnection = false;
  final controlScriptList = <String>[].obs;
  final isBatchSwitching = false.obs;
  final isStartupAutoDeploying = false.obs;

  ScriptService get _scriptService => Get.find<ScriptService>();

  @override
  void onInit() {
    _loadSelection();
    super.onInit();
  }

  void setControlScripts(Iterable<String> scripts) {
    final normalized = scripts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    controlScriptList.value = normalized;
    _storage.write(
      StorageKey.homeControlScriptList.name,
      jsonEncode(controlScriptList.toList()),
    );
  }

  void _loadSelection() {
    final raw = _storage.read(StorageKey.homeControlScriptList.name);
    if (raw == null) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      setControlScripts(decoded.map((e) => e.toString()));
    } catch (_) {}
  }

  bool isAllControlScriptsRunning() {
    final scripts = validControlScripts;
    if (scripts.isEmpty) {
      return false;
    }
    return scripts.every(
      (name) =>
          _scriptService.scriptModelMap.containsKey(name) &&
          _scriptService.isRunning(name),
    );
  }

  Future<void> toggleAllControlScripts(bool enable) async {
    if (isBatchSwitching.value) {
      return;
    }
    final scripts = validControlScripts;
    if (scripts.isEmpty) {
      return;
    }

    isBatchSwitching.value = true;
    try {
      if (enable) {
        for (final name in scripts) {
          await _scriptService.startScript(name);
        }
      } else {
        for (final name in scripts) {
          await _scriptService.stopScript(name);
        }
      }
    } finally {
      isBatchSwitching.value = false;
    }
  }

  List<String> get validControlScripts => controlScriptList
      .where((name) => _scriptService.scriptModelMap.containsKey(name))
      .toList();

  int get validControlScriptCount => validControlScripts.length;

  Future<void> checkStartupConnection() async {
    if (_hasCheckedStartupConnection) {
      return;
    }
    _hasCheckedStartupConnection = true;

    final connected = await ApiClient().testAddress();
    if (connected) {
      return;
    }

    Get.snackbar(I18n.login_error.tr, I18n.login_error_msg.tr);
    if (!Get.isRegistered<SettingsController>()) {
      return;
    }

    final settings = Get.find<SettingsController>();
    if (!PlatformUtils.isDesktop || !settings.autoDeploy.value) {
      return;
    }

    isStartupAutoDeploying.value = true;
    try {
      final serverController = Get.isRegistered<ServerController>()
          ? Get.find<ServerController>()
          : Get.put<ServerController>(ServerController(), permanent: true);
      await serverController.run();
      await _waitUntilDeployFinished(serverController);
    } finally {
      isStartupAutoDeploying.value = false;
    }
  }

  Future<void> _waitUntilDeployFinished(ServerController controller) async {
    var retries = 0;
    while (controller.isDeployLoading.value && retries < 240) {
      retries += 1;
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }
}
