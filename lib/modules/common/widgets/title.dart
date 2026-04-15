import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/server/index.dart';
import 'package:oasx/translation/i18n_content.dart';

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
  const HomeTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
          const SizedBox(width: 14),
          Flexible(child: _TitleLabel(text: 'OASX / ${I18n.home.tr}')),
        ],
      ),
    );
  }
}

class SettingTitle extends StatelessWidget {
  const SettingTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final backButton = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (backButton) ...[
            BackButton(onPressed: _backHomeOrPop),
            const SizedBox(width: 8),
          ],
          Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
          const SizedBox(width: 14),
          Flexible(child: _TitleLabel(text: 'OASX / ${I18n.setting.tr}')),
        ],
      ),
    );
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
  const ServerTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final backButton = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (backButton &&
                !Get.find<ServerController>().isDeployLoading.value) {
              return const Row(
                mainAxisSize: MainAxisSize.min,
                children: [BackButton(), SizedBox(width: 8)],
              );
            }
            return const SizedBox.shrink();
          }),
          Image.asset('assets/images/Icon-app.png', height: 30, width: 30),
          const SizedBox(width: 14),
          const Flexible(child: _TitleLabel(text: 'OASX / Server')),
        ],
      ),
    );
  }
}

class _TitleLabel extends StatelessWidget {
  const _TitleLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
