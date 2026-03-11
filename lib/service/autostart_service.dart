import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AutoStartService extends GetxService {
  final _storage = GetStorage();

  final enableLaunchAtStartup = false.obs;
  final isApplying = false.obs;

  late final String _appName;
  late final String _packageName;

  @override
  Future<void> onInit() async {
    enableLaunchAtStartup.value =
        _storage.read(StorageKey.launchAtStartup.name) ?? false;

    final packageInfo = await _tryGetPackageInfo();
    _appName = _normalizeNonEmpty(packageInfo?.appName, fallback: 'OASX');
    _packageName =
        _normalizeNonEmpty(packageInfo?.packageName, fallback: 'oasx');

    if (PlatformUtils.isDesktop) {
      await refresh();
    }
    super.onInit();
  }

  Future<void> refresh() async {
    if (!PlatformUtils.isDesktop) return;
    final enabled = await _isEnabledOnSystem();
    enableLaunchAtStartup.value = enabled;
    _storage.write(StorageKey.launchAtStartup.name, enabled);
  }

  Future<void> updateLaunchAtStartupEnable(bool enabled) async {
    if (!PlatformUtils.isDesktop) return;
    if (isApplying.value) return;

    isApplying.value = true;
    try {
      final ok = await _setEnabledOnSystem(enabled);
      await refresh();
      if (!ok || enableLaunchAtStartup.value != enabled) {
        Get.snackbar(I18n.tip.tr, I18n.launchAtStartupUpdateFailed.tr);
      }
    } finally {
      isApplying.value = false;
    }
  }

  Future<bool> _isEnabledOnSystem() async {
    if (Platform.isWindows) return _isWindowsEnabled();
    if (Platform.isMacOS) return _isMacEnabled();
    if (Platform.isLinux) return _isLinuxEnabled();
    return false;
  }

  Future<bool> _setEnabledOnSystem(bool enabled) async {
    if (Platform.isWindows) return _setWindowsEnabled(enabled);
    if (Platform.isMacOS) return _setMacEnabled(enabled);
    if (Platform.isLinux) return _setLinuxEnabled(enabled);
    return false;
  }

  Future<bool> _isWindowsEnabled() async {
    final result = await Process.run('schtasks', [
      '/Query',
      '/TN',
      _windowsTaskName,
    ]);
    return result.exitCode == 0;
  }

  Future<bool> _setWindowsEnabled(bool enabled) async {
    if (enabled) {
      final xmlFile =
          File('${Directory.systemTemp.path}\\${_windowsTaskName}_task.xml');
      try {
        await xmlFile.writeAsString(_buildWindowsTaskXml());
        await _runWindowsElevated([
          '/Create',
          '/XML',
          xmlFile.path,
          '/TN',
          _windowsTaskName,
          '/F',
        ]);
        return _isWindowsEnabled();
      } finally {
        try {
          await xmlFile.delete();
        } catch (_) {}
      }
    }

    await _runWindowsElevated([
      '/Delete',
      '/TN',
      _windowsTaskName,
      '/F',
    ]);
    return !(await _isWindowsEnabled());
  }

  Future<void> _runWindowsElevated(List<String> schtasksArgs) async {
    final escaped =
        schtasksArgs.map((a) => "'${a.replaceAll("'", "''")}'").join(',');
    await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      'Start-Process -FilePath schtasks -ArgumentList $escaped -Verb RunAs -Wait',
    ]);
  }

  String get _windowsTaskName {
    final normalized = _appName.replaceAll(RegExp(r'\s+'), '');
    return 'OASX';
  }

  String _buildWindowsTaskXml() {
    final exe = _xmlEscape(Platform.resolvedExecutable);
    return '''<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>3</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$exe</Command>
    </Exec>
  </Actions>
</Task>''';
  }

  Future<bool> _isMacEnabled() async {
    return File(_macLaunchAgentPath).exists();
  }

  Future<bool> _setMacEnabled(bool enabled) async {
    final file = File(_macLaunchAgentPath);
    if (enabled) {
      await file.parent.create(recursive: true);
      await file.writeAsString(
        _buildMacPlist(),
        encoding: utf8,
      );
      return true;
    }

    if (await file.exists()) {
      await file.delete();
    }
    return true;
  }

  String get _macLaunchAgentPath {
    final home = _homeDirPath();
    final label = '${_packageName}.autostart';
    return '$home/Library/LaunchAgents/$label.plist';
  }

  String _buildMacPlist() {
    final label = '${_packageName}.autostart';
    final executable = _xmlEscape(Platform.resolvedExecutable);
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>$label</string>
    <key>ProgramArguments</key>
    <array>
      <string>$executable</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>LimitLoadToSessionType</key>
    <array>
      <string>Aqua</string>
    </array>
  </dict>
</plist>
''';
  }

  String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<bool> _isLinuxEnabled() async {
    return File(_linuxAutostartDesktopPath).exists();
  }

  Future<bool> _setLinuxEnabled(bool enabled) async {
    final file = File(_linuxAutostartDesktopPath);
    if (enabled) {
      await file.parent.create(recursive: true);
      await file.writeAsString(
        _buildLinuxDesktopEntry(),
        encoding: utf8,
      );
      return true;
    }

    if (await file.exists()) {
      await file.delete();
    }
    return true;
  }

  String get _linuxAutostartDesktopPath {
    final configHome = Platform.environment['XDG_CONFIG_HOME'];
    final base = (configHome != null && configHome.trim().isNotEmpty)
        ? configHome.trim()
        : '${_homeDirPath()}/.config';
    return '$base/autostart/${_packageName}.desktop';
  }

  String _buildLinuxDesktopEntry() {
    final executable = _escapeDesktopExec(Platform.resolvedExecutable);
    final name = _appName;
    return '''
[Desktop Entry]
Type=Application
Version=1.0
Name=$name
Exec=$executable
Terminal=false
X-GNOME-Autostart-enabled=true
''';
  }

  String _escapeDesktopExec(String executablePath) {
    if (executablePath.contains(' ')) {
      return '"${executablePath.replaceAll('"', '\\"')}"';
    }
    return executablePath;
  }

  String _homeDirPath() {
    final homeKey = Platform.isWindows ? 'USERPROFILE' : 'HOME';
    final home = Platform.environment[homeKey];
    if (home != null && home.trim().isNotEmpty) {
      return home.trim();
    }
    return Directory.current.path;
  }

  String _normalizeNonEmpty(String? value, {required String fallback}) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  Future<PackageInfo?> _tryGetPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }
}
