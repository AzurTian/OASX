import 'package:get/get.dart';
import 'package:oasx/controller/home/home_dashboard_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeDashboardController>()) {
      Get.put<HomeDashboardController>(HomeDashboardController(),
          permanent: true);
    }
  }
}
