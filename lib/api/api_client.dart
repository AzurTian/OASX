import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_nb_net/flutter_net.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_interceptor.dart';
import 'package:oasx/config/constants.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/home/models/script_statistics_models.dart';
import 'package:oasx/translation/i18n.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/check_version.dart';

import './home_model.dart';
import './update_info_model.dart';
import 'dio_http_cache/dio_http_cache.dart';

part 'api_client_menu_config.dart';
part 'api_client_script.dart';
part 'api_client_feedback.dart';
part 'api_client_statistics.dart';

class ApiResult<T> {
  ApiResult({this.data, this.error, this.code});

  final T? data;
  final String? error;
  final int? code;

  bool get isSuccess => error == null || error!.isEmpty;

  ApiResult.success(this.data)
      : error = null,
        code = null;

  ApiResult.failure(this.error, [this.code]) : data = null;

  factory ApiResult.fromJson(Map<String, dynamic> json) {
    return ApiResult(
      data: json['data'],
      error: json['error'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'error': error,
      'code': code,
    };
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late final CacheOptions _cacheOptions;

  ApiClient._internal() {
    final temporaryDirectory =
        GetStorage().read(StorageKey.temporaryDirectory.name) ?? '';
    final cacheStore =
        kIsWeb ? MemCacheStore() : FileCacheStore(temporaryDirectory);
    _cacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
      cipher: null,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false,
    );
    NetOptions.instance
        .setConnectTimeout(const Duration(seconds: 3))
        .enableLogger(false)
        .addInterceptor(
          DioCacheInterceptor(
            options: _cacheOptions,
          ),
        )
        .addInterceptor(ApiInterceptor())
        .create();
  }

  String address = '127.0.0.1:22288';

  void setAddress(String address) {
    this.address = address;
    NetOptions.instance.dio.options.baseUrl = address;
  }

  Options _buildUpdateCheckOptions(UpdateCheckPolicy cachePolicy) {
    final dioCacheOptions = cachePolicy == UpdateCheckPolicy.manualNoCache
        ? _cacheOptions.copyWith(
            policy: CachePolicy.refresh,
            hitCacheOnErrorExcept: const Nullable<List<int>>(null),
          )
        : _cacheOptions;
    return buildCacheOptions(
      const Duration(days: 7),
      options: dioCacheOptions.toOptions(),
      forceRefresh: cachePolicy == UpdateCheckPolicy.manualNoCache,
    );
  }

  Future<ApiResult<T>> request<T>(
    Future<Result<dynamic>> Function() apiFn, {
    void Function(String msg, int code)? onError,
  }) async {
    try {
      final res = await apiFn();
      return res.when(
        success: (data) => ApiResult.fromJson(data),
        failure: (msg, code) {
          onError?.call(msg, code);
          return ApiResult.failure(msg, code);
        },
      );
    } catch (e) {
      printError(info: '$e');
      return ApiResult.failure(e.toString());
    }
  }

  Future<bool> testAddress() async {
    final res = await request(() => get('/test'), onError: (msg, code) {});
    return res.isSuccess && res.data == 'success';
  }

  Future<bool> killServer() async {
    final res =
        await request(() => get('/home/kill_server'), onError: (msg, code) {});
    return res.isSuccess && res.data == 'success';
  }

  Future<bool> notifyTest(String setting, String title, String content) async {
    final res = await request(
      () => post(
        '/home/notify_test',
        queryParameters: {
          'setting': setting,
          'title': title,
          'content': content,
        },
      ),
    );
    if (res.isSuccess && res.data == true) {
      Get.snackbar(I18n.notifyTestSuccess.tr, '');
      return true;
    }
    Get.snackbar(I18n.notifyTestFailed.tr, res.data.toString());
    return false;
  }

  Future<GithubVersionModel> getGithubVersion({
    UpdateCheckPolicy cachePolicy = UpdateCheckPolicy.autoCached,
  }) async {
    final res = await request(
      () => get(
        updateUrlGithub,
        options: _buildUpdateCheckOptions(cachePolicy),
        decodeType: GithubVersionModel(),
      ),
    );
    return res.isSuccess ? res.data : GithubVersionModel();
  }

  Future<ReadmeGithubModel> getGithubReadme() async {
    final res = await request(
      () => get(
        readmeUrlGithub,
        options: buildCacheOptions(
          const Duration(days: 7),
          options: Options(extra: {'cache': true}),
        ),
        decodeType: ReadmeGithubModel(),
      ),
    );
    return res.isSuccess ? res.data : ReadmeGithubModel();
  }

  Future<UpdateInfoModel> getUpdateInfo() async {
    final res = await request(() => get('/home/update_info'));
    return res.isSuccess ? UpdateInfoModel.fromJson(res.data) : UpdateInfoModel();
  }

  Future<String?> getExecuteUpdate() async {
    final res = await request(() => get('/home/execute_update'));
    if (res.isSuccess) {
      showDialog('Update', res.data.toString());
      return res.data;
    }
    return res.data;
  }

  Future<bool> putChineseTranslate() async {
    final res = await request(
      () => put(
        '/home/chinese_translate',
        data: Messages().all_cn_translate,
      ),
    );
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, Map<String, String>>> getAdditionalTranslate() async {
    final res = await request(() => get('/home/additional_translate'));
    final result = <String, Map<String, String>>{};
    if (res.isSuccess) {
      result['zh_CN'] = (res.data['zh-CN'] as Map).cast<String, String>();
      result['en_US'] = (res.data['en-US'] as Map).cast<String, String>();
    }
    return result;
  }
}


