import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/controllers/statistics_controller.dart';
import 'package:oasx/modules/args/index.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ArgsController>()) {
      Get.lazyPut<ArgsController>(() => ArgsController(), fenix: true);
    }
    if (!Get.isRegistered<HomeDashboardController>()) {
      Get.put<HomeDashboardController>(HomeDashboardController(),
          permanent: true);
    }
    if (!Get.isRegistered<HomeStatisticsController>()) {
      Get.put<HomeStatisticsController>(HomeStatisticsController(),
          permanent: true);
    }
  }
}



