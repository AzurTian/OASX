part of overview;

class OverviewController extends GetxController with LogMixin {
  final String name;
  final scriptService = Get.find<ScriptService>();
  late final scriptModel = scriptService.findScriptModel(name)!;

  OverviewController({required this.name});
}
