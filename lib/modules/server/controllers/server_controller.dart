import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:process_run/shell.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/log/log_mixin.dart';
import 'package:oasx/modules/server/models/deploy_git_prefetcher.dart';
import 'package:oasx/modules/server/models/deploy_python_config.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/script_service.dart';

class ServerController extends GetxController with LogMixin {
  @override
  int get maxLines => 1000;

  final rootPathServer = ''.obs;
  final rootPathAuthenticated = true.obs;
  final showDeploy = true.obs;
  final deployContent = ''.obs;
  final autoLoginAfterDeploy = false.obs;
  final isDeployLoading = false.obs;
  final _storage = GetStorage();
  Shell? shell;
  var shellController = ShellLinesController();
  var shellErrorController = ShellLinesController();

  /// Tracks whether taskkill already reported that pythonw.exe is absent.
  var _pythonwNotRunningLogged = false;

  @override
  void onInit() {
    rootPathServer.value =
        _storage.read(StorageKey.rootPathServer.name) ??
        'Please set OAS root path';
    autoLoginAfterDeploy.value =
        _storage.read(StorageKey.autoLoginAfterDeploy.name) ?? false;
    shell = getShell;
    shellController.stream.listen(
      (event) => addLog(!event.contains('INFO') ? 'INFO: $event' : event),
    );
    shellErrorController.stream.listen(_addShellErrorLine);
    rootPathAuthenticated.value = authenticatePath(rootPathServer.value);
    if (rootPathAuthenticated.value) {
      readDeploy();
    }
    super.onInit();
  }

  void updateRootPathServer(String value) {
    rootPathAuthenticated.value = authenticatePath(value);
    rootPathServer.value = value;
    shell = getShell;
    Get.find<SettingsController>().storage.write(
      StorageKey.rootPathServer.name,
      rootPathServer.value,
    );
    if (rootPathAuthenticated.value) {
      readDeploy();
    }
  }

  bool authenticatePath(String root) {
    root.replaceAll('\\', '/');
    try {
      final rootDir = Directory(root);
      if (!rootDir.existsSync()) {
        return false;
      }
      final deploy = File('${rootDir.path}/config/deploy.yaml');
      if (!deploy.existsSync()) {
        return false;
      }
      final pythonConfig = DeployPythonConfig.read(rootDir.path);
      final python = File(pythonConfig.getPythonPath(rootDir.path));
      if (!python.existsSync()) {
        return false;
      }
      final git = File('${rootDir.path}/toolkit/Git/mingw64/bin/git.exe');
      if (!git.existsSync()) {
        return false;
      }
      final installer = File('${rootDir.path}/deploy/installer.py');
      if (!installer.existsSync()) {
        return false;
      }
    } catch (e) {
      printError(info: e.toString());
      return false;
    }
    return true;
  }

  void readDeploy() {
    final filePath = '${rootPathServer.value}\\config\\deploy.yaml';
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        deployContent.value = file.readAsStringSync();
      } else {
        deployContent.value = 'File not found';
      }
    } catch (e) {
      deployContent.value = 'Error reading file: $e';
    }
  }

  void writeDeploy(String value) {
    final filePath = '${rootPathServer.value}\\config\\deploy.yaml';
    deployContent.value = value;
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        file.writeAsStringSync(deployContent.value);
      } else {
        deployContent.value = 'File not found';
      }
    } catch (e) {
      deployContent.value = 'Error writing file: $e';
    }
  }

  /// Imports one YAML file into the current OAS deploy config path.
  bool importDeployFile(String sourcePath) {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      return false;
    }
    if (!sourcePath.toLowerCase().endsWith('.yaml')) {
      return false;
    }
    final targetPath = '${rootPathServer.value}\\config\\deploy.yaml';
    try {
      source.copySync(targetPath);
      readDeploy();
      return true;
    } catch (e) {
      deployContent.value = 'Error importing file: $e';
      return false;
    }
  }

  /// Exports the saved deploy.yaml file to a user-selected path.
  bool exportDeployFile(String targetPath) {
    if (targetPath.trim().isEmpty) {
      return false;
    }
    final sourcePath = '${rootPathServer.value}\\config\\deploy.yaml';
    final normalizedTarget = targetPath.toLowerCase().endsWith('.yaml')
        ? targetPath
        : '$targetPath.yaml';
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        return false;
      }
      source.copySync(normalizedTarget);
      return true;
    } catch (e) {
      deployContent.value = 'Error exporting file: $e';
      return false;
    }
  }

  String get pathGit => '${rootPathServer.value}\\toolkit\\Git\\mingw64\\bin';
  String get pathPython => '${rootPathServer.value}\\toolkit';
  String get pathAdb =>
      '${rootPathServer.value}\\toolkit\\Lib\\site-packages\\adbutils\\binaries';
  String get pathScripts => '${rootPathServer.value}\\toolkit\\Scripts';
  String get pathSeparator => Platform.isWindows ? ';' : ':';
  Map<String, String> get pathPATH => {
    'PATH': [
      rootPathServer.value,
      pathGit,
      pathPython,
      pathAdb,
      pathScripts,
    ].join(pathSeparator),
  };

  Shell get getShell => Shell(
    workingDirectory: rootPathServer.value,
    runInShell: true,
    environment: pathPATH,
    stdout: shellController.sink,
    stderr: shellErrorController.sink,
    verbose: false,
  );

  /// Runs one shell command and records failures with the requested severity.
  Future<bool> runShell(
    String command, {
    bool allowFailure = false,
    bool ignorePythonwNotRunning = false,
  }) async {
    if (ignorePythonwNotRunning) {
      _pythonwNotRunningLogged = false;
    }
    try {
      await shell!.run(command);
      return true;
    } on ShellException catch (e) {
      if (ignorePythonwNotRunning && _isPythonwNotRunningException(e)) {
        if (!_pythonwNotRunningLogged) {
          addLog('WARNING: pythonw.exe is not running, skip taskkill');
        }
        return true;
      }
      _addShellExceptionLog(e, allowFailure: allowFailure);
      return false;
    }
  }

  /// Adds a shell exception using info or error severity.
  void _addShellExceptionLog(
    ShellException exception, {
    required bool allowFailure,
  }) {
    final prefix = allowFailure ? 'INFO' : 'ERROR';
    addLog('$prefix: ${exception.toString()}');
  }

  /// Detects the taskkill exit code used when pythonw.exe is absent.
  bool _isPythonwNotRunningException(ShellException exception) {
    final lower = exception.message.toLowerCase();
    return exception.result?.exitCode == 128 &&
        lower.contains('taskkill') &&
        lower.contains('pythonw.exe');
  }

  void _addShellErrorLine(String line) {
    final lower = line.toLowerCase();
    final expectedTaskKillOutput = _isExpectedTaskKillOutput(lower);
    if (expectedTaskKillOutput) {
      _pythonwNotRunningLogged = true;
      final message = line.replaceFirst(
        RegExp(r'^\s*ERROR:\s*', caseSensitive: false),
        '',
      );
      addLog('WARNING: $message');
      return;
    }
    if (_isGitProgressLine(lower)) {
      upsertLog('INFO: $line', _isGitProgressLog);
      return;
    }
    final isError = lower.contains('fatal:') || lower.contains('error:');
    addLog('${isError ? 'ERROR' : 'INFO'}: $line');
  }

  /// Detects taskkill output when no pythonw.exe process is running.
  bool _isExpectedTaskKillOutput(String lowerLine) {
    return lowerLine.contains('pythonw.exe') &&
        (lowerLine.contains('not found') || lowerLine.contains('没有找到'));
  }

  bool _isGitProgressLine(String lowerLine) {
    return lowerLine.startsWith('remote: enumerating objects:') ||
        lowerLine.startsWith('remote: counting objects:') ||
        lowerLine.startsWith('remote: compressing objects:') ||
        lowerLine.startsWith('receiving objects:') ||
        lowerLine.startsWith('resolving deltas:') ||
        lowerLine.startsWith('updating files:');
  }

  bool _isGitProgressLog(String log) {
    return _isGitProgressLine(log.replaceFirst('INFO: ', '').toLowerCase());
  }

  Future<bool> prefetchRepository() async {
    final prefetcher = DeployGitPrefetcher(
      rootPath: rootPathServer.value,
      log: addLog,
      runShell: runShell,
    );
    return prefetcher.prefetchRepository();
  }

  Future<void> run() async {
    isDeployLoading.value = true;
    try {
      if (Get.isRegistered<SettingsController>()) {
        await Get.find<SettingsController>().killServer(
          showTip: false,
          resetDashboardToDisconnected: false,
        );
      }
      clearLog();
      shell!.kill();
      await runShell('echo OAS working directory: ');
      await runShell('cd');
      await runShell(
        'taskkill /f /t /im pythonw.exe',
        ignorePythonwNotRunning: true,
      );
      await prefetchRepository();
      final pythonConfig = DeployPythonConfig.read(rootPathServer.value);
      await runShell(
        shellExecutableArguments(
          pythonConfig.getPythonPath(rootPathServer.value),
          ['-m', 'deploy.installer'],
        ),
      );
      await runShell('echo Start OAS');
      unawaited(
        runShell(
          shellExecutableArguments(
            pythonConfig.getPythonwPath(rootPathServer.value),
            ['server.py'],
          ),
        ),
      );

      final shouldAutoLogin = _resolveAutoLoginAfterDeploy();
      if (!shouldAutoLogin) {
        return;
      }

      final address = _storage.read(StorageKey.address.name) ?? '';
      if (address.isEmpty) {
        return;
      }
      await Future.delayed(const Duration(seconds: 2));
      await _tryConnect(
        address,
        retries: 60,
        retryDelay: const Duration(milliseconds: 500),
      );
    } finally {
      isDeployLoading.value = false;
    }
  }

  bool _resolveAutoLoginAfterDeploy() {
    if (Get.isRegistered<SettingsController>()) {
      final value = Get.find<SettingsController>().autoLoginAfterDeploy.value;
      autoLoginAfterDeploy.value = value;
      return value;
    }
    final value = _storage.read(StorageKey.autoLoginAfterDeploy.name) ?? false;
    autoLoginAfterDeploy.value = value;
    return value;
  }

  Future<bool> _tryConnect(
    String rawAddress, {
    int retries = 1,
    Duration retryDelay = const Duration(milliseconds: 500),
  }) async {
    final address =
        rawAddress.startsWith('http://') || rawAddress.startsWith('https://')
        ? rawAddress
        : 'http://$rawAddress';
    ApiClient().setAddress(address);

    for (int i = 0; i < retries; i++) {
      final connected = await ApiClient().testAddress();
      if (connected) {
        try {
          if (Get.isRegistered<HomeDashboardController>()) {
            await Get.find<HomeDashboardController>()
                .refreshAfterExternalConnected();
          } else if (Get.isRegistered<ScriptService>()) {
            await Get.find<ScriptService>().reloadFromServer();
          }
        } catch (_) {
          // Keep navigation behavior even if dashboard refresh fails here.
        }
        await Get.find<LocaleService>().refreshTransFromRemote();
        Get.offAllNamed('/home');
        return true;
      }
      if (i < retries - 1) {
        await Future.delayed(retryDelay);
      }
    }
    return false;
  }
}
