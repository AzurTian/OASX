part of 'home_dashboard_controller.dart';

extension HomeDashboardStartupX on HomeDashboardController {
  Future<void> checkStartupConnection() async {
    if (HomeDashboardController._hasCheckedStartupConnection) {
      return;
    }
    HomeDashboardController._hasCheckedStartupConnection = true;
    await _runStartupConnectionCheck(
      enableAutoDeploy: true,
      showFailureSnack: true,
    );
  }

  Future<void> refreshAfterSettingsChanged() async {
    await _scriptService.resetDashboardState();
    await _runStartupConnectionCheck(
      enableAutoDeploy: true,
      showFailureSnack: true,
    );
  }

  Future<void> retryStartupConnection() async {
    await _runStartupConnectionCheck(
      enableAutoDeploy: false,
      showFailureSnack: false,
    );
  }

  Future<void> refreshAfterExternalConnected() async {
    if (isStartupChecking.value) {
      return;
    }
    isStartupChecking.value = true;
    try {
      await _refreshScriptsAfterConnected();
    } finally {
      isStartupChecking.value = false;
      startupLoadingMessage.value = '';
    }
  }

  void markConnectionFailedFromKillServer() {
    isStartupChecking.value = false;
    isStartupAutoDeploying.value = false;
    startupLoadingMessage.value = '';
    isStartupConnectionFailed.value = true;
  }

  Future<void> _runStartupConnectionCheck({
    required bool enableAutoDeploy,
    required bool showFailureSnack,
  }) async {
    if (isStartupChecking.value) {
      return;
    }
    isStartupChecking.value = true;
    isStartupConnectionFailed.value = false;
    startupLoadingMessage.value = I18n.homeLoadingAutoLogin;
    try {
      final connected = await ApiClient().testAddress();
      if (connected) {
        await _refreshScriptsAfterConnected();
        await _refreshTranslationsAfterLogin();
        return;
      }

      if (showFailureSnack) {
        Get.snackbar(I18n.loginError.tr, I18n.loginErrorMsg.tr);
      }
      if (!enableAutoDeploy || !Get.isRegistered<SettingsController>()) {
        isStartupConnectionFailed.value = true;
        return;
      }

      final settings = Get.find<SettingsController>();
      if (!PlatformUtils.isDesktop || !settings.autoDeploy.value) {
        isStartupConnectionFailed.value = true;
        return;
      }

      startupLoadingMessage.value = I18n.homeLoadingAutoDeploying;
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

      startupLoadingMessage.value = I18n.homeLoadingAutoLogin;
      final connectedAfterDeploy = await _waitForAddressConnected();
      if (connectedAfterDeploy) {
        await _refreshScriptsAfterConnected();
        await _refreshTranslationsAfterLogin();
        return;
      }

      isStartupConnectionFailed.value = true;
    } finally {
      isStartupChecking.value = false;
      startupLoadingMessage.value = '';
    }
  }

  Future<void> _refreshScriptsAfterConnected() async {
    isStartupConnectionFailed.value = false;
    startupLoadingMessage.value = I18n.homeLoadingConfigDetail;
    await _scriptService.reloadFromServer();
  }

  Future<void> _refreshTranslationsAfterLogin() async {
    if (!Get.isRegistered<LocaleService>()) {
      return;
    }
    try {
      await Get.find<LocaleService>().refreshTransFromRemote();
    } catch (_) {
      // Keep login flow working even if translation refresh fails.
    }
  }

  Future<bool> _waitForAddressConnected({
    int retries = 10,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (var i = 0; i < retries; i++) {
      final connected = await ApiClient().testAddress();
      if (connected) {
        return true;
      }
      if (i < retries - 1) {
        await Future.delayed(delay);
      }
    }
    return false;
  }

  Future<void> _waitUntilDeployFinished(ServerController controller) async {
    var retries = 0;
    while (controller.isDeployLoading.value && retries < 20) {
      retries += 1;
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }
}

