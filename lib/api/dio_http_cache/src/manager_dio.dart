// ignore_for_file: depend_on_referenced_packages, constant_identifier_names, no_leading_underscores_for_local_identifiers, prefer_conditional_assignment, deprecated_member_use, avoid_print, prefer_is_empty

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import './core/config.dart';
import './core/manager.dart';
import './core/obj.dart';

part 'manager_dio_internal.dart';
part 'manager_dio_tools.dart';

const DIO_CACHE_KEY_TRY_CACHE = "dio_cache_try_cache";
const DIO_CACHE_KEY_MAX_AGE = "dio_cache_max_age";
const DIO_CACHE_KEY_MAX_STALE = "dio_cache_max_stale";
const DIO_CACHE_KEY_PRIMARY_KEY = "dio_cache_primary_key";
const DIO_CACHE_KEY_SUB_KEY = "dio_cache_sub_key";
const DIO_CACHE_KEY_FORCE_REFRESH = "dio_cache_force_refresh";
const DIO_CACHE_HEADER_KEY_DATA_SOURCE = "dio_cache_header_key_data_source";

typedef _ParseHeadCallback = void Function(
  Duration? _maxAge,
  Duration? _maxStale,
);

class DioCacheManager {
  late CacheManager _manager;
  InterceptorsWrapper? _interceptor;
  late String? _baseUrl;
  late String _defaultRequestMethod;

  DioCacheManager(CacheConfig config) {
    _manager = CacheManager(config);
    _baseUrl = config.baseUrl;
    _defaultRequestMethod = config.defaultRequestMethod;
  }

  get interceptor {
    _interceptor ??= InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    );
    return _interceptor;
  }

  _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if ((options.extra[DIO_CACHE_KEY_TRY_CACHE] ?? false) != true) {
      return handler.next(options);
    }
    if (true == options.extra[DIO_CACHE_KEY_FORCE_REFRESH]) {
      return handler.next(options);
    }
    var responseDataFromCache = await _pullFromCacheBeforeMaxAge(options);
    if (null != responseDataFromCache) {
      return handler.resolve(
        _buildResponse(
          responseDataFromCache,
          responseDataFromCache.statusCode,
          options,
        ),
        true,
      );
    }
    return handler.next(options);
  }

  _onResponse(Response response, ResponseInterceptorHandler handler) async {
    if ((response.requestOptions.extra[DIO_CACHE_KEY_TRY_CACHE] ?? false) ==
            true &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      await _pushToCache(response);
    }
    return handler.next(response);
  }

  _onError(DioError e, ErrorInterceptorHandler handler) async {
    if ((e.requestOptions.extra[DIO_CACHE_KEY_TRY_CACHE] ?? false) == true) {
      if (true == e.requestOptions.extra[DIO_CACHE_KEY_FORCE_REFRESH]) {
        return handler.next(e);
      }
      var responseDataFromCache =
          await _pullFromCacheBeforeMaxStale(e.requestOptions);
      if (null != responseDataFromCache) {
        var response = _buildResponse(
          responseDataFromCache,
          responseDataFromCache.statusCode,
          e.requestOptions,
        );
        return handler.resolve(response);
      }
    }
    return handler.next(e);
  }

  Response _buildResponse(
    CacheObj obj,
    int? statusCode,
    RequestOptions options,
  ) =>
      _managerBuildResponse(this, obj, statusCode, options);

  Future<CacheObj?> _pullFromCacheBeforeMaxAge(RequestOptions options) {
    return _manager.pullFromCacheBeforeMaxAge(
      _getPrimaryKeyFromOptions(options),
      subKey: _getSubKeyFromOptions(options),
    );
  }

  Future<CacheObj?> _pullFromCacheBeforeMaxStale(RequestOptions options) {
    return _manager.pullFromCacheBeforeMaxStale(
      _getPrimaryKeyFromOptions(options),
      subKey: _getSubKeyFromOptions(options),
    );
  }

  Future<bool> _pushToCache(Response response) {
    RequestOptions options = response.requestOptions;
    Duration? maxAge = options.extra[DIO_CACHE_KEY_MAX_AGE];
    Duration? maxStale = options.extra[DIO_CACHE_KEY_MAX_STALE];
    if (null == maxAge) {
      _tryParseHead(response, maxStale, (_maxAge, _maxStale) {
        maxAge = _maxAge;
        maxStale = _maxStale;
      });
    }
    List<int>? data;
    if (options.responseType == ResponseType.bytes) {
      data = response.data;
    } else {
      data = utf8.encode(jsonEncode(response.data));
    }
    var obj = CacheObj(
      _getPrimaryKeyFromOptions(options),
      data!,
      subKey: _getSubKeyFromOptions(options),
      maxAge: maxAge,
      maxStale: maxStale,
      statusCode: response.statusCode,
      headers: utf8.encode(jsonEncode(response.headers.map)),
    );
    return _manager.pushToCache(obj);
  }

  void _tryParseHead(
    Response response,
    Duration? maxStale,
    _ParseHeadCallback callback,
  ) =>
      _managerTryParseHead(this, response, maxStale, callback);

  Duration? _tryGetDurationFromMap(Map<String, String?> parameters, String key) {
    if (parameters.containsKey(key)) {
      var value = int.tryParse(parameters[key]!);
      if (null != value && value >= 0) {
        return Duration(seconds: value);
      }
    }
    return null;
  }

  String _getPrimaryKeyFromOptions(RequestOptions options) {
    var primaryKey = options.extra.containsKey(DIO_CACHE_KEY_PRIMARY_KEY)
        ? options.extra[DIO_CACHE_KEY_PRIMARY_KEY]
        : _getPrimaryKeyFromUri(options.uri);
    return "${_getRequestMethod(options.method)}-$primaryKey";
  }

  String _getRequestMethod(String? requestMethod) {
    if (null != requestMethod && requestMethod.length > 0) {
      return requestMethod.toUpperCase();
    }
    return _defaultRequestMethod.toUpperCase();
  }

  String? _getSubKeyFromOptions(RequestOptions options) {
    return options.extra.containsKey(DIO_CACHE_KEY_SUB_KEY)
        ? options.extra[DIO_CACHE_KEY_SUB_KEY]
        : _getSubKeyFromUri(options.uri, data: options.data);
  }

  String _getPrimaryKeyFromUri(Uri uri) => "${uri.host}${uri.path}";

  String _getSubKeyFromUri(Uri uri, {dynamic data}) =>
      "${data?.toString()}_${uri.query}";
}
