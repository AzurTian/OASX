part of 'script_service.dart';

extension ScriptServiceWsX on ScriptService {
  Future<void> connectScript(String name) async {
    if (!scriptModelMap.containsKey(name)) {
      addScriptModel(name);
    }
    if (!Get.isRegistered<ScriptLogController>(tag: name)) {
      Get.put(
        ScriptLogController(name: name),
        tag: name,
        permanent: true,
      );
    }
    wsService.removeAllListeners(name);
    final client = await wsService.connect(
      name: name,
      listener: (mg) => wsListener(mg, name),
    );
    client.status.listen(
      (wsStatus) => scriptModelMap[name]?.update(state: wsStatus.scriptState),
    );
  }

  Future<void> startScript(String name) async {
    if (!scriptModelMap.containsKey(name)) return;
    if (isRunning(name)) return;
    await connectScript(name);
    await wsService.send(name, 'start');
  }

  void wsListener(dynamic message, String name) {
    if (message is! String) {
      printError(info: 'Websocket push data is not of type string and map');
      return;
    }
    if (!message.startsWith('{') || !message.endsWith('}')) {
      if (!Get.isRegistered<ScriptLogController>(tag: name)) {
        Get.put(
          ScriptLogController(name: name),
          tag: name,
          permanent: true,
        );
      }
      Get.find<ScriptLogController>(tag: name).addLog(message);
      return;
    }
    final data = jsonDecode(message) as Map<String, dynamic>;
    if (data.containsKey('state')) {
      scriptModelMap[name]!.update(state: ScriptState.getState(data['state']));
      return;
    }
    if (!data.containsKey('schedule')) {
      return;
    }

    final run = data['schedule']['running'] as Map;
    final pending = data['schedule']['pending'] as List<dynamic>;
    final waiting = data['schedule']['waiting'] as List<dynamic>;
    final runningTask = run.isNotEmpty
        ? TaskItemModel(name, run['name'], run['next_run'])
        : TaskItemModel.empty();
    final pendingList = pending
        .map((e) => TaskItemModel(name, e['name'], e['next_run']))
        .toList();
    final waitingList = waiting
        .map((e) => TaskItemModel(name, e['name'], e['next_run']))
        .toList();
    scriptModelMap[name]!.update(
      runningTask: runningTask,
      pendingTaskList: pendingList,
      waitingTaskList: waitingList,
    );
  }

  Future<void> stopScript(String name) async {
    if (!scriptModelMap.containsKey(name)) return;
    await wsService.send(name, 'stop');
  }
}
