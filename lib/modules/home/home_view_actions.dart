part of 'index.dart';

extension _HomeViewActions on _HomeViewState {
  Widget _buildDashboardBody() {
    return Obx(() {
      if (controller.startupLoadingMessage.value.isNotEmpty) {
        return const SizedBox.expand();
      }
      if (controller.isStartupConnectionFailed.value &&
          scriptService.scriptOrderList.isEmpty) {
        return _buildConnectionFailedView();
      }
      return Padding(
        padding: const EdgeInsets.all(12),
        child: ConfigWorkbench(
          controller: controller,
          scriptService: scriptService,
          loadingAddScript: _isAddingScript,
          refreshingScripts: _isRefreshingScripts,
          onAddScriptTap: _onAddScriptCardTap,
          onRefreshScriptsTap: _onRefreshScriptsTap,
        ),
      );
    });
  }

  Widget _buildConnectionFailedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              if (controller.isStartupChecking.value) {
                return const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                );
              }
              return Icon(
                Icons.cloud_off_rounded,
                size: 34,
                color: Theme.of(context).colorScheme.outline,
              );
            }),
            const SizedBox(height: 12),
            Text(
              I18n.homeConnectionRetryHint.tr,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddScriptCardTap() async {
    if (_isAddingScript) {
      return;
    }
    await showAddConfigDialog(
      context,
      onSubmitting: () => _setAddingScript(true),
      onSubmitDone: () {
        _setAddingScript(false);
        controller.syncWorkspaceState();
      },
    );
  }

  Future<void> _onRefreshScriptsTap() async {
    if (_isRefreshingScripts) {
      return;
    }
    _setRefreshingScripts(true);
    try {
      await controller.retryStartupConnection();
      controller.syncWorkspaceState();
    } catch (_) {
      Get.snackbar(I18n.loginError.tr, I18n.loginErrorMsg.tr);
    } finally {
      _setRefreshingScripts(false);
    }
  }
}
