// ignore_for_file: no_leading_underscores_for_local_identifiers, prefer_conditional_assignment, avoid_print
part of 'manager_dio.dart';

Response _managerBuildResponse(
  DioCacheManager manager,
  CacheObj obj,
  int? statusCode,
  RequestOptions options,
) {
  Headers? headers;
  if (null != obj.headers) {
    headers = Headers.fromMap(
      (Map<String, List<dynamic>>.from(jsonDecode(utf8.decode(obj.headers!))))
          .map((k, v) => MapEntry(k, List<String>.from(v))),
    );
  }
  if (null == headers) {
    headers = Headers();
    options.headers.forEach((k, v) => headers!.add(k, v ?? ""));
  }
  headers.add(DIO_CACHE_HEADER_KEY_DATA_SOURCE, "from_cache");
  dynamic data = obj.content;
  if (options.responseType != ResponseType.bytes) {
    data = jsonDecode(utf8.decode(data));
  }
  return Response(
    data: data,
    headers: headers,
    requestOptions:
        options.copyWith(extra: options.extra..remove(DIO_CACHE_KEY_TRY_CACHE)),
    statusCode: statusCode ?? 200,
  );
}

void _managerTryParseHead(
  DioCacheManager manager,
  Response response,
  Duration? maxStale,
  _ParseHeadCallback callback,
) {
  Duration? _maxAge;
  var cacheControl = response.headers.value(HttpHeaders.cacheControlHeader);
  if (null != cacheControl) {
    Map<String, String?> parameters;
    try {
      parameters = HeaderValue.parse(
        "${HttpHeaders.cacheControlHeader}: $cacheControl",
        parameterSeparator: ",",
        valueSeparator: "=",
      ).parameters;
      _maxAge = manager._tryGetDurationFromMap(parameters, "s-maxage");
      if (null == _maxAge) {
        _maxAge = manager._tryGetDurationFromMap(parameters, "max-age");
      }
      if (null == maxStale) {
        maxStale = manager._tryGetDurationFromMap(parameters, "max-stale");
      }
    } catch (e) {
      print(e);
    }
  } else {
    var expires = response.headers.value(HttpHeaders.expiresHeader);
    if (null != expires && expires.length > 4) {
      DateTime? endTime;
      try {
        endTime = HttpDate.parse(expires).toLocal();
      } catch (e) {
        print(e);
      }
      if (null != endTime && endTime.compareTo(DateTime.now()) >= 0) {
        _maxAge = endTime.difference(DateTime.now());
      }
    }
  }
  callback(_maxAge, maxStale);
}

