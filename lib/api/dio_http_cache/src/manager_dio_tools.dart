// ignore_for_file: prefer_is_empty
part of 'manager_dio.dart';

extension DioCacheManagerToolsX on DioCacheManager {
  Future<bool> delete(String primaryKey,
          {String? requestMethod, String? subKey}) =>
      _manager.delete(
        "${_getRequestMethod(requestMethod)}-$primaryKey",
        subKey: subKey,
      );

  Future<bool> deleteByPrimaryKeyWithUri(Uri uri, {String? requestMethod}) =>
      delete(_getPrimaryKeyFromUri(uri), requestMethod: requestMethod);

  Future<bool> deleteByPrimaryKey(String path, {String? requestMethod}) =>
      deleteByPrimaryKeyWithUri(
        _getUriByPath(_baseUrl, path),
        requestMethod: requestMethod,
      );

  Future<bool> deleteByPrimaryKeyAndSubKeyWithUri(
    Uri uri, {
    String? requestMethod,
    String? subKey,
    dynamic data,
  }) =>
      delete(
        _getPrimaryKeyFromUri(uri),
        requestMethod: requestMethod,
        subKey: subKey ?? _getSubKeyFromUri(uri, data: data),
      );

  Future<bool> deleteByPrimaryKeyAndSubKey(
    String path, {
    String? requestMethod,
    Map<String, dynamic>? queryParameters,
    String? subKey,
    dynamic data,
  }) =>
      deleteByPrimaryKeyAndSubKeyWithUri(
        _getUriByPath(_baseUrl, path,
            data: data, queryParameters: queryParameters),
        requestMethod: requestMethod,
        subKey: subKey,
        data: data,
      );

  Future<bool> clearExpired() => _manager.clearExpired();

  Future<bool> clearAll() => _manager.clearAll();

  Uri _getUriByPath(
    String? baseUrl,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    if (!path.startsWith(RegExp(r'https?:'))) {
      assert(baseUrl != null && baseUrl.length > 0);
    }
    return RequestOptions(
      baseUrl: baseUrl,
      path: path,
      data: data,
      queryParameters: queryParameters,
    ).uri;
  }
}
