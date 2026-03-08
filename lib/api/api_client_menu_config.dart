part of 'api_client.dart';

extension ApiClientMenuConfigX on ApiClient {
  Future<Map<String, List<String>>> getScriptMenu() async {
    final res = await request(() => get('/script_menu'));
    return ((res.data ?? {}) as Map).map(
      (k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
    );
  }

  Future<Map<String, List<String>>> getHomeMenu() async {
    final res = await request(() => get('/home/home_menu'));
    return ((res.data ?? {}) as Map).map(
      (k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
    );
  }

  Future<List<String>> getConfigList() async {
    final res = await request(() => get('/config_list'));
    return ['Home', ...(res.data?.cast<String>() ?? [])];
  }

  Future<List<String>> getScriptList() async {
    final res = await request(() => get('/config_list'));
    return [...(res.data?.cast<String>() ?? [])];
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
    return res.data?.cast<String>() ?? ['template'];
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
