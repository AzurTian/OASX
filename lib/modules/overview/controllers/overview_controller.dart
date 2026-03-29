part of overview;

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
