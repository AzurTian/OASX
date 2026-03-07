import 'package:get/get.dart';

import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/index.dart';
import 'package:oasx/modules/home/home_binding.dart';
import 'package:oasx/modules/overview/index.dart';
import 'package:oasx/modules/server/index.dart';
import 'package:oasx/modules/settings/index.dart';

class Routes {
  static const initial = '/home';

  static final routes = [
    GetPage(
      name: '/home',
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/overview',
      page: () => const OverviewRouteView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ArgsController>()) {
          Get.lazyPut<ArgsController>(() => ArgsController(), fenix: true);
        }
      }),
    ),
    GetPage(
      name: '/settings',
      page: () => const SettingsView(),
    ),
    GetPage(
      name: '/server',
      page: () => const ServerView(),
      binding: BindingsBuilder(() {
        Get.put<ServerController>(ServerController());
      }),
    ),
  ];
}

