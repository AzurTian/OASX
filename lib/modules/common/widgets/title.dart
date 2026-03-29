import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/modules/server/index.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

Widget getTitle(BuildContext context, {String? routePath}) {
  final resolvedRoutePath = _resolveRoutePath(context, routePath: routePath);
  return switch (resolvedRoutePath) {
    '/settings' => const SettingTitle(),
    '/server' => const ServerTitle(),
    _ => const HomeTitleBar(),
  };
}

String _resolveRoutePath(BuildContext context, {String? routePath}) {
  final explicitRoute = routePath?.trim() ?? '';
  if (explicitRoute.isNotEmpty) {
    return explicitRoute;
  }

  final routingCurrent = Get.routing.current;
  if (routingCurrent.isNotEmpty) {
    return routingCurrent;
  }

  final routeName = ModalRoute.of(context)?.settings.name;
  if (routeName != null && routeName.isNotEmpty) {
    return routeName;
  }
  return Get.currentRoute;
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
      Text(
        'OASX / ${I18n.home.tr}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      PlatformUtils.isWindows
          ? const SizedBox()
          : const Flexible(child: SizedBox()),
    ]
        .toRow(
          separator: const SizedBox(width: 8),
          mainAxisAlignment: MainAxisAlignment.start,
        )
        .padding(left: 5);
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
      if (backButton) BackButton(onPressed: _backHomeOrPop),
      Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
      const SizedBox(width: 6),
      Text(
        'OASX / ${I18n.setting.tr}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      PlatformUtils.isWindows
          ? const SizedBox()
          : const Flexible(child: SizedBox()),
    ]
        .toRow(
          separator: const SizedBox(width: 8),
          mainAxisAlignment: MainAxisAlignment.start,
        )
        .padding(left: 5);
  }

  void _backHomeOrPop() {
    final canPop = Get.key.currentState?.canPop() ?? false;
    if (canPop || Get.previousRoute.isNotEmpty) {
      Get.back();
      return;
    }
    Get.offAllNamed('/home');
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
          mainAxisAlignment: MainAxisAlignment.start,
        )
        .padding(left: 5);
  }
}
