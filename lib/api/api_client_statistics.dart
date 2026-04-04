part of 'api_client.dart';

extension ApiClientStatisticsX on ApiClient {
  Future<ScriptStatisticsDateList> getScriptStatisticsDates(
    String scriptName,
  ) async {
    final path = '/stats/${Uri.encodeComponent(scriptName)}/dates';
    final res = await request(() => get(path));
    if (!res.isSuccess || res.data is! Map) {
      throw Exception(res.error ?? 'Invalid statistics dates response');
    }
    return ScriptStatisticsDateList.fromJson(
      Map<String, dynamic>.from(res.data),
    );
  }

  Future<ScriptStatisticsDay> getScriptStatisticsDay(
    String scriptName,
    String dateKey,
  ) async {
    final path = '/stats/${Uri.encodeComponent(scriptName)}?date=$dateKey';
    final res = await request(() => get(path));
    if (!res.isSuccess || res.data is! Map) {
      throw Exception(res.error ?? 'Invalid statistics day response');
    }
    return parseScriptStatisticsDayAsync(
      Map<String, dynamic>.from(res.data),
      dateKey: dateKey,
    );
  }

  Uri buildScriptStatisticsSseUri(String scriptName, String dateKey) {
    final addressText = address.trim();
    final baseAddress =
        addressText.startsWith('http://') || addressText.startsWith('https://')
            ? addressText
            : 'http://$addressText';
    return Uri.parse(
      '$baseAddress/stats/${Uri.encodeComponent(scriptName)}/stream?date=$dateKey',
    );
  }
}
