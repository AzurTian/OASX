import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/utils/time_utils.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/server/index.dart';

part 'home_dashboard_controller_linking.dart';
part 'home_dashboard_controller_startup.dart';
part 'home_dashboard_controller_workspace.dart';

/// Defines the visible dashboard health state for a script.
enum HomeScriptStateFilter {
  all,
  running,
  abnormal,
  stopped,
  offline,
}

/// Defines the responsive layout mode for the home workbench.
enum HomeWorkbenchLayoutMode {
  threePane,
  twoPane,
  singlePane,
}

/// Defines the visible page when the workbench collapses to a single pane.
enum HomeWorkbenchPage {
  scripts,
  workspace,
}

/// Defines the visible home workbench tab for the active script.
enum HomeWorkbenchTab {
  status,
  tasks,
  logs,
}

/// Records which workbench tab opened the task parameter editor.
enum HomeTaskParameterEntrySource {
  overview,
  tasks,
}

/// Defines the task catalog filter shown in the active script workspace.
enum HomeTaskCatalogFilter {
  all,
  enabled,
  disabled,
}

const double kHomeWorkbenchPaneGap = 12;
const double kHomeWorkbenchScriptListWidth = 340;
const double kHomeWorkbenchMinDetailsWidth = 360;
const double kHomeWorkbenchMinLogWidth = 360;

/// Resolves the current responsive layout mode from the available width.
HomeWorkbenchLayoutMode resolveHomeWorkbenchLayoutMode(double maxWidth) {
  final availableWidth = maxWidth.isFinite ? maxWidth : 0.0;
  const threePaneWidth = kHomeWorkbenchScriptListWidth +
      kHomeWorkbenchMinDetailsWidth +
      kHomeWorkbenchMinLogWidth +
      kHomeWorkbenchPaneGap * 2;
  if (availableWidth >= threePaneWidth) {
    return HomeWorkbenchLayoutMode.threePane;
  }
  const twoPaneWidth = kHomeWorkbenchScriptListWidth +
      kHomeWorkbenchMinDetailsWidth +
      kHomeWorkbenchPaneGap;
  if (availableWidth >= twoPaneWidth) {
    return HomeWorkbenchLayoutMode.twoPane;
  }
  return HomeWorkbenchLayoutMode.singlePane;
}

class HomeDashboardController extends GetxController {
  final _storage = GetStorage();
  static bool _hasCheckedStartupConnection = false;
  Worker? _workspaceSyncWorker;
  final controlScriptList = <String>[].obs;
  final isBatchSwitching = false.obs;
  final isStartupChecking = false.obs;
  final isStartupConnectionFailed = false.obs;
  final isStartupAutoDeploying = false.obs;
  final startupLoadingMessage = ''.obs;
  final isLinkModeEnabled = false.obs;
  final linkedScriptList = <String>[].obs;
  final searchQuery = ''.obs;
  final stateFilter = HomeScriptStateFilter.all.obs;
  final activeScriptName = ''.obs;
  final selectedScriptList = <String>[].obs;
  final workbenchPage = HomeWorkbenchPage.scripts.obs;
  final activeWorkbenchTab = HomeWorkbenchTab.status.obs;
  final _lastPrimaryWorkbenchTab = HomeWorkbenchTab.status.obs;
  final taskCatalogFilter = HomeTaskCatalogFilter.all.obs;
  final activeTaskName = ''.obs;
  final _taskParameterEntrySource = Rxn<HomeTaskParameterEntrySource>();

  ScriptService get _scriptService => Get.find<ScriptService>();

  @override
  void onInit() {
    _loadSelection();
    syncWorkspaceState();
    _workspaceSyncWorker = everAll([
      _scriptService.scriptOrderList,
      _scriptService.scriptModelMap,
    ], (_) {
      syncWorkspaceState();
    });
    super.onInit();
  }

  @override
  void onClose() {
    _workspaceSyncWorker?.dispose();
    _workspaceSyncWorker = null;
    super.onClose();
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
}
