import 'package:get/get.dart';

import 'package:oasx/views/args/args_view.dart';
import 'package:oasx/views/home/home_binding.dart';
import 'package:oasx/views/home/home_view.dart';
import 'package:oasx/views/overview/overview_view.dart';
import 'package:oasx/views/settings/settings_view.dart';
import 'package:oasx/views/server/server_view.dart';

class Routes {
  /// when the app is opened, this page will be the first to be shown
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
        Get.lazyPut<ArgsController>(() => ArgsController(), fenix: true);
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
