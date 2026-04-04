import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:oasx/service/app_update/models/app_update_plan.dart';
import 'package:oasx/service/app_update_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:styled_widget/styled_widget.dart';

/// Renders the shared app update dialog.
class AppUpdateDialog extends StatelessWidget {
  /// Creates the shared app update dialog.
  const AppUpdateDialog({
    super.key,
    required this.plan,
    required this.service,
  });

  /// Update plan resolved for the current platform.
  final AppUpdatePlan plan;

  /// Service used to trigger update actions.
  final AppUpdateService service;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(I18n.findNewVersion.tr),
      content: _buildContent().constrained(width: 320, height: 360),
      actions: _buildActions(),
    );
  }

  /// Builds the update summary content.
  Widget _buildContent() {
    return SingleChildScrollView(
      child: <Widget>[
        Text('${I18n.latestVersion.tr}: ${plan.release.version ?? 'v0.0.0'}'),
        Text('${I18n.currentVersion.tr}: ${plan.currentVersion}'),
        if (!plan.canInstallInApp) Text(I18n.updateReleasePageOnly.tr),
        MarkdownBody(data: plan.release.body ?? ''),
      ].toColumn(crossAxisAlignment: CrossAxisAlignment.start),
    );
  }

  /// Builds the dialog actions for release-page and install flows.
  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => service.openReleasePage(plan.release),
        child: Text(I18n.openReleasePage.tr),
      ),
      if (plan.canInstallInApp)
        Obx(() {
          return FilledButton(
            onPressed: service.isInstalling.value
                ? null
                : () => service.installUpdate(plan),
            child: Text(
              service.isInstalling.value
                  ? I18n.updateDownloading.tr
                  : plan.installActionKey.tr,
            ),
          );
        }),
    ];
  }
}
