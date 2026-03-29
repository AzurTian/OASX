import 'package:flutter_nb_net/flutter_net.dart';
import 'package:get/get.dart' hide Response;
import 'package:oasx/translation/i18n_content.dart';

class ApiInterceptor extends Interceptor {
  static const _startTimeKey = 'api_start_time';
  static const _maxLen = 200; // 鏈€澶ф墦鍗伴暱搴?

  String _short(Object? data) {
    if (data == null) return 'null';
    final str = data.toString();
    if (str.length > _maxLen) {
      return '${str.substring(0, _maxLen)}...';
    }
    return str;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;

    final method = options.method;
    final uri = options.uri.toString();
    final queryParams = options.queryParameters;
    final data = options.data;

    printInfo(
      info:
          '[$method]$uri | query=${_short(queryParams)} | body=${_short(data)}',
    );
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final start = response.requestOptions.extra[_startTimeKey] as int?;
    final duration =
        start != null ? DateTime.now().millisecondsSinceEpoch - start : null;
    final status = response.statusCode;
    final uri = response.requestOptions.uri;
    printInfo(
      info:
          '[$status]$uri | ${duration ?? '-'} ms | data=${_short(response.data)}',
    );
    response.data = {'code': status, 'error': '', 'data': response.data};
    handler.resolve(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response == null) {
      handler.next(err);
      return;
    }
    int code = err.response!.statusCode!;
    final data = err.response!.data;
    String msg = I18n.networkUnknownError.tr;
    if (data is Map) {
      final message = data['message'];
      final detail = data['detail'];
      final value = message ?? detail;
      if (value != null && value.toString().trim().isNotEmpty) {
        msg = value.toString();
      }
    } else if (data != null && data.toString().trim().isNotEmpty) {
      msg = data.toString();
    }
    switch (code) {
      case 403:
        break;
      case 404:
        showNetErrCodeSnackBar(I18n.networkNotFound.tr, code);
        break;
      case 500:
      case 400:
        showErrSnackBar(I18n.networkServerError.tr, code, msg);
        break;
      default:
        showNetErrCodeSnackBar(msg, code);
        break;
    }
    err.response?.data = {'code': code, 'error': msg, 'data': ''};
    handler.resolve(err.response!);
  }

  void showNetErrSnackBar() {
    Get.snackbar(I18n.networkError.tr, I18n.networkConnectTimeout.tr,
        duration: const Duration(seconds: 5));
  }

  void showNetErrCodeSnackBar(String msg, int code) {
    Get.snackbar(
        I18n.networkError.tr, '${I18n.networkErrorCode.tr}: $code | $msg',
        duration: const Duration(seconds: 5));
  }

  void showErrSnackBar(String title, int code, String msg) {
    Get.snackbar('$title | $code', msg, duration: const Duration(seconds: 5));
  }
}

