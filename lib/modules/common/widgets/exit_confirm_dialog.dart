import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Captures the user's desktop close-button choice.
class ExitConfirmResult {
  /// Creates a confirmed desktop exit decision.
  const ExitConfirmResult({
    required this.minimizeToTray,
    required this.shutdownOas,
    required this.skipConfirm,
  });

  /// Whether confirmation should minimize OASX to system tray.
  final bool minimizeToTray;

  /// Whether true exits should shut down OAS.
  final bool shutdownOas;

  /// Whether future desktop close confirmations should be skipped.
  final bool skipConfirm;
}

/// Desktop close confirmation dialog.
class ExitConfirmDialog extends StatefulWidget {
  /// Creates the dialog with values synchronized from settings.
  const ExitConfirmDialog({
    required this.initialMinimizeToTray,
    required this.initialShutdownOas,
    super.key,
  });

  /// Initial value for the minimize-to-tray setting.
  final bool initialMinimizeToTray;

  /// Initial value for the shut-down-OAS-on-exit setting.
  final bool initialShutdownOas;

  @override
  State<ExitConfirmDialog> createState() => _ExitConfirmDialogState();
}

class _ExitConfirmDialogState extends State<ExitConfirmDialog> {
  /// Current minimize-to-tray selection.
  late bool _minimizeToTray;

  /// Current shut-down-OAS selection.
  late bool _shutdownOas;

  /// Current skip-confirmation selection.
  bool _skipConfirm = false;

  @override
  void initState() {
    super.initState();
    _minimizeToTray =
        widget.initialMinimizeToTray && !widget.initialShutdownOas;
    _shutdownOas = widget.initialShutdownOas;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text(I18n.exitOasx.tr)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ExitPrimaryOptions(
              minimizeToTray: _minimizeToTray,
              shutdownOas: _shutdownOas,
              onMinimizeToTrayChanged: _updateMinimizeToTray,
              onShutdownOasChanged: _updateShutdownOas,
            ),
            const SizedBox(height: 16),
            _ExitDialogFooter(
              skipConfirm: _skipConfirm,
              onSkipConfirmChanged: (value) {
                setState(() => _skipConfirm = value);
              },
              onCancel: Get.back,
              onConfirm: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    Get.back(
      result: ExitConfirmResult(
        minimizeToTray: _minimizeToTray,
        shutdownOas: _shutdownOas,
        skipConfirm: _skipConfirm,
      ),
    );
  }

  /// Updates the tray choice and clears OAS shutdown when selected.
  void _updateMinimizeToTray(bool value) {
    setState(() {
      _minimizeToTray = value;
      if (value) _shutdownOas = false;
    });
  }

  /// Updates the OAS shutdown choice and clears tray minimize when selected.
  void _updateShutdownOas(bool value) {
    setState(() {
      _shutdownOas = value;
      if (value) _minimizeToTray = false;
    });
  }
}

class _ExitPrimaryOptions extends StatelessWidget {
  const _ExitPrimaryOptions({
    required this.minimizeToTray,
    required this.shutdownOas,
    required this.onMinimizeToTrayChanged,
    required this.onShutdownOasChanged,
  });

  final bool minimizeToTray;
  final bool shutdownOas;
  final ValueChanged<bool> onMinimizeToTrayChanged;
  final ValueChanged<bool> onShutdownOasChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runAlignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        _ExitOptionCheckbox(
          value: minimizeToTray,
          label: I18n.exitDialogMinimizeToTray.tr,
          onChanged: onMinimizeToTrayChanged,
        ),
        _ExitOptionCheckbox(
          value: shutdownOas,
          label: I18n.killOasServer.tr,
          onChanged: onShutdownOasChanged,
        ),
      ],
    );
  }
}

class _ExitOptionCheckbox extends StatelessWidget {
  const _ExitOptionCheckbox({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (next) {
                if (next == null) return;
                onChanged(next);
              },
            ),
            const SizedBox(width: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ExitDialogFooter extends StatelessWidget {
  const _ExitDialogFooter({
    required this.skipConfirm,
    required this.onSkipConfirmChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool skipConfirm;
  final ValueChanged<bool> onSkipConfirmChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: _SkipConfirmCheckbox(
                value: skipConfirm,
                onChanged: onSkipConfirmChanged,
              ),
            ),
          ),
          TextButton(onPressed: onCancel, child: Text(I18n.cancel.tr)),
          const SizedBox(width: 8),
          FilledButton(onPressed: onConfirm, child: Text(I18n.confirm.tr)),
        ],
      ),
    );
  }
}

class _SkipConfirmCheckbox extends StatelessWidget {
  const _SkipConfirmCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(top: 2, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.78,
              child: Checkbox(
                value: value,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (next) {
                  if (next == null) return;
                  onChanged(next);
                },
              ),
            ),
            const SizedBox(width: 2),
            Text(I18n.doNotRemindAgain.tr, style: style),
          ],
        ),
      ),
    );
  }
}
