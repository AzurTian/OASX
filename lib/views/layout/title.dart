import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/views/server/server_view.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

Widget getTitle() {
  final routePath = Get.currentRoute;
  return switch (routePath) {
    '/home' => const HomeTitleBar(),
    '/overview' => const OverviewTitle(),
    '/settings' => const SettingTitle(),
    '/server' => const ServerTitle(),
    _ => const SettingTitle(),
  };
}

class HomeTitleBar extends StatelessWidget {
  const HomeTitleBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return <Widget>[
      Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
      const SizedBox(width: 6),
      Text('OASX / ${I18n.home.tr}',
          style: Theme.of(context).textTheme.titleMedium),
      PlatformUtils.isWindows
          ? const SizedBox()
          : const Flexible(child: SizedBox()),
    ]
        .toRow(
            separator: const SizedBox(width: 8),
            mainAxisAlignment: MainAxisAlignment.start)
        .padding(left: 5);
  }
}

class OverviewTitle extends StatelessWidget {
  const OverviewTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final showBackButton = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    final scriptName = Get.parameters['script']?.trim() ?? '';
    final suffix = scriptName.isEmpty
        ? I18n.log.tr
        : '${scriptName.toUpperCase()} / ${I18n.log.tr}';

    return <Widget>[
      if (showBackButton)
        BackButton(
          onPressed: _backHomeOrPop,
        ),
      Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
      const SizedBox(width: 6),
      Text('OASX / $suffix', style: Theme.of(context).textTheme.titleMedium),
      PlatformUtils.isWindows
          ? const SizedBox()
          : const Flexible(child: SizedBox()),
    ]
        .toRow(
            separator: const SizedBox(width: 8),
            mainAxisAlignment: MainAxisAlignment.start)
        .padding(left: 5);
  }

  void _backHomeOrPop() {
    if (Get.previousRoute.isNotEmpty) {
      Get.back();
      return;
    }
    Get.offAllNamed('/home');
  }
}

class SettingTitle extends StatelessWidget {
  const SettingTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final backButton = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    return <Widget>[
      if (backButton) BackButton(onPressed: () => Get.offAllNamed('/home')),
      Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
      const SizedBox(width: 6),
      Text('OASX / ${I18n.setting.tr}',
          style: Theme.of(context).textTheme.titleMedium),
      PlatformUtils.isWindows
          ? const SizedBox()
          : const Flexible(child: SizedBox()),
    ]
        .toRow(
            separator: const SizedBox(width: 8),
            mainAxisAlignment: MainAxisAlignment.start)
        .padding(left: 5);
  }
}

class ServerTitle extends StatelessWidget {
  const ServerTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final backButton = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    return <Widget>[
      Obx(() {
        if (backButton && !Get.find<ServerController>().isDeployLoading.value) {
          return const BackButton();
        }
        return const SizedBox();
      }),
      Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
      const SizedBox(width: 6),
      Text('OASX / Server', style: Theme.of(context).textTheme.titleMedium),
      PlatformUtils.isWindows
          ? const SizedBox()
          : const Flexible(child: SizedBox()),
    ]
        .toRow(
            separator: const SizedBox(width: 8),
            mainAxisAlignment: MainAxisAlignment.start)
        .padding(left: 5);
  }
}
