import 'dart:convert';
import 'dart:io';

import 'package:oasx/api/github_release_model.dart';
import 'package:oasx/service/app_update/installers/app_update_installer.dart';
import 'package:oasx/service/app_update/models/app_update_plan.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

/// Applies Windows portable zip updates through an external PowerShell script.
class WindowsUpdateInstaller implements AppUpdateInstaller {
  /// Creates a Windows update installer.
  const WindowsUpdateInstaller();

  @override
  String get installActionKey => I18n.downloadAndUpdate;

  @override
  Future<bool> canInstallInApp() async {
    final platformUtils = PlatformUtils();
    return !await platformUtils.isInstalledFromMicrosoftStore();
  }

  @override
  Future<GithubReleaseAssetModel?> selectAsset(
      GithubReleaseModel release) async {
    final assets = release.assets ?? const <GithubReleaseAssetModel>[];
    for (final asset in assets) {
      final name = (asset.name ?? '').toLowerCase();
      if (name.contains('windows') && name.endsWith('.zip')) {
        return asset;
      }
    }
    return null;
  }

  @override
  Future<void> install(DownloadedUpdatePackage package) async {
    final currentProcessId = pid;
    final executablePath = Platform.resolvedExecutable;
    final installDirectory = File(executablePath).parent.path;
    final executableName = File(executablePath).uri.pathSegments.last;
    final scriptFile = File('${package.filePath}.ps1');
    final scriptContent = _buildScript(
      currentProcessId: currentProcessId,
      installDirectory: installDirectory,
      zipPath: package.filePath,
      executableName: executableName,
    );
    await scriptFile.writeAsString(scriptContent, encoding: utf8);
    await Process.start(
      'powershell',
      [
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
      ],
      runInShell: true,
    );
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      exit(0);
    });
  }

  /// Builds the Windows handoff script that applies the downloaded zip.
  String _buildScript({
    required int currentProcessId,
    required String installDirectory,
    required String zipPath,
    required String executableName,
  }) {
    final installDirLiteral = _psLiteral(installDirectory);
    final zipPathLiteral = _psLiteral(zipPath);
    final executableLiteral = _psLiteral(executableName);
    return r'''
$ErrorActionPreference = 'Stop'
$processId = __PROCESS_ID__
$installDir = __INSTALL_DIR__
$zipPath = __ZIP_PATH__
$exeName = __EXE_NAME__
$workRoot = Join-Path ([System.IO.Path]::GetDirectoryName($zipPath)) 'windows_apply'
$stageDir = Join-Path $workRoot 'stage'
$backupDir = Join-Path $workRoot 'backup'

for ($index = 0; $index -lt 120; $index++) {
  if (-not (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
    break
  }
  Start-Sleep -Milliseconds 500
}

if (Test-Path $workRoot) {
  Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $workRoot -Force | Out-Null
Expand-Archive -LiteralPath $zipPath -DestinationPath $stageDir -Force

if (Test-Path $backupDir) {
  Remove-Item -LiteralPath $backupDir -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path $installDir) {
  Move-Item -LiteralPath $installDir -Destination $backupDir -Force
}
Move-Item -LiteralPath $stageDir -Destination $installDir -Force

$targetExe = Join-Path $installDir $exeName
Start-Process -FilePath $targetExe
'''
        .replaceFirst('__PROCESS_ID__', currentProcessId.toString())
        .replaceFirst('__INSTALL_DIR__', installDirLiteral)
        .replaceFirst('__ZIP_PATH__', zipPathLiteral)
        .replaceFirst('__EXE_NAME__', executableLiteral);
  }

  /// Converts a value into a PowerShell single-quoted literal.
  String _psLiteral(String value) {
    final escaped = value.replaceAll("'", "''");
    return "'$escaped'";
  }
}
