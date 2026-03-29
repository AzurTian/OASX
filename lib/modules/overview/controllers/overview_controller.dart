import 'package:get/get.dart';

import 'package:oasx/modules/log/log_mixin.dart';
import 'package:oasx/service/script_service.dart';

class OverviewController extends GetxController with LogMixin {
  final String name;
  final scriptService = Get.find<ScriptService>();
  late final scriptModel = scriptService.findScriptModel(name)!;

  OverviewController({required this.name});

  @override
  int get maxLines => 800;

  @override
  int get maxBuffer => 6000;

  @override
  int get maxArchivedLines => 12000;
}
