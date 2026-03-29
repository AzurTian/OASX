import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/common/widgets/primary_navigation_shell.dart';
import 'package:oasx/modules/home/home_binding.dart';
import 'package:oasx/modules/home/index.dart';
import 'package:oasx/modules/server/index.dart';
import 'package:oasx/modules/settings/index.dart';
import 'package:oasx/utils/platform_utils.dart';

class Routes {
  static const initial = '/home';

  static final routes = [
    GetPage(
      name: '/home',
      page: () => _buildPrimaryPage('/home'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/settings',
      page: () => _buildPrimaryPage('/settings'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/server',
      page: () => const ServerView(),
      binding: BindingsBuilder(() {
        Get.put<ServerController>(ServerController());
      }),
    ),
  ];

  static Widget _buildPrimaryPage(String routePath) {
    if (PlatformUtils.isDesktop) {
      return switch (routePath) {
        '/settings' => const SettingsView(),
        _ => const HomeView(),
      };
    }
    return PrimaryNavigationShell(routePath: routePath);
  }
}
