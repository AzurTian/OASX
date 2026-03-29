import 'package:get/get.dart';
import 'package:oasx/modules/log/log_mixin.dart';
import 'package:oasx/service/script_service.dart';

/// Script-scoped log controller with shared log buffering behavior.
class ScriptLogController extends GetxController with LogMixin {
  /// Script name used to resolve the backing script model.
  final String name;

  /// Script service lookup for the associated script model.
  final ScriptService scriptService = Get.find<ScriptService>();

  /// Cached script model resolved by name.
  late final scriptModel = scriptService.findScriptModel(name)!;

  /// Creates a log controller for the given script name.
  ScriptLogController({required this.name});

  /// Maximum live log lines kept in memory for display.
  @override
  int get maxLines => 800;

  /// Total buffered logs allowed before trimming.
  @override
  int get maxBuffer => 6000;

  /// Maximum archived lines kept for history.
  @override
  int get maxArchivedLines => 12000;
}
