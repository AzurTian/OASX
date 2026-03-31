part of 'dashboard_controller.dart';

extension HomeDashboardLayoutX on HomeDashboardController {
  /// Returns the persisted split ratio after sanitizing the stored value.
  void _loadWorkbenchSplitRatio() {
    final storedRatio = _storage.read(StorageKey.homeWorkbenchSplitRatio.name);
    workbenchSplitRatio.value = sanitizeHomeWorkbenchSplitRatio(storedRatio);
  }

  /// Persists the latest valid three-pane split ratio.
  void setWorkbenchSplitRatio(double value) {
    final normalized = sanitizeHomeWorkbenchSplitRatio(value);
    if ((workbenchSplitRatio.value - normalized).abs() < 0.0001) {
      return;
    }
    workbenchSplitRatio.value = normalized;
    _storage.write(StorageKey.homeWorkbenchSplitRatio.name, normalized);
  }
}

