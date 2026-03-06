import 'package:get/get.dart';
import 'package:oasx/controller/home/home_dashboard_controller.dart';
import 'package:oasx/views/args/args_view.dart';

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
  }
}
