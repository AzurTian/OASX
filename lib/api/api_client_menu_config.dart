part of 'api_client.dart';

extension ApiClientMenuConfigX on ApiClient {
  Future<Map<String, List<String>>> getScriptMenu() async {
    final res = await request(() => get('/script_menu'));
    return _asMenuMap(res.data);
  }

  Future<Map<String, List<String>>> getHomeMenu() async {
    final res = await request(() => get('/home/home_menu'));
    return _asMenuMap(res.data);
  }

  Future<List<String>> getConfigList() async {
    final res = await request(() => get('/config_list'));
    return ['Home', ..._asStringList(res.data)];
  }

  Future<List<String>> getScriptList() async {
    final res = await request(() => get('/config_list'));
    return _asStringList(res.data);
  }

  Future<String> getNewConfigName() async {
    final res = await request(() => get('/config_new_name'));
    return res.isSuccess ? res.data : '';
  }

  Future<List<String>> configCopy(String newName, String template) async {
    final res = await request(
      () => post(
        '/config_copy',
        queryParameters: {'file': newName, 'template': template},
      ),
    );
    return ['Home', ...(res.data?.cast<String>() ?? [])];
  }

  Future<List<String>> getConfigAll() async {
    final res = await request(() => get('/config_all'));
    final result = _asStringList(res.data);
    return result.isEmpty ? ['template'] : result;
  }

  Future<bool> deleteConfig(String name) async {
    final res = await request(
      () => delete('/config', queryParameters: {'name': name}),
    );
    return res.isSuccess && res.data;
  }

  Future<bool> renameConfig(String oldName, String newName) async {
    final res = await request(
      () => put(
        '/config',
        queryParameters: {'old_name': oldName, 'new_name': newName},
      ),
    );
    return res.isSuccess && res.data;
  }

  Future<bool> copyTask(
    String taskName,
    String copyConfigName,
    String sourceConfigName,
  ) async {
    final res = await request(
      () => put(
        '/config/task/copy',
        queryParameters: {
          'task_name': taskName,
          'dest_config_name': copyConfigName,
          'source_config_name': sourceConfigName,
        },
      ),
    );
    return res.isSuccess && res.data;
  }

  Future<bool> copyGroup(
    String taskName,
    String groupName,
    String copyConfigName,
    String sourceConfigName,
  ) async {
    final res = await request(
      () => put(
        '/config/task/group/copy',
        queryParameters: {
          'task_name': taskName,
          'group_name': groupName,
          'dest_config_name': copyConfigName,
          'source_config_name': sourceConfigName,
        },
      ),
    );
    return res.isSuccess && res.data;
  }
}

Map<String, List<String>> _asMenuMap(dynamic value) {
  if (value is! Map) {
    return const <String, List<String>>{};
  }
  return value.map(
    (key, item) => MapEntry(
      key.toString(),
      item is List
          ? item.map((entry) => entry.toString()).toList()
          : <String>[],
    ),
  );
}

List<String> _asStringList(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }
  return value.map((entry) => entry.toString()).toList();
}
