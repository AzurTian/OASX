import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/global.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/utils/platform_utils.dart';

class SettingsController extends GetxController {
  final storage = GetStorage();

  late String temporaryDirectory;
  final autoLoginAfterDeploy = false.obs;
  final autoDeploy = false.obs;

  final address = ''.obs;
  final username = ''.obs;
  final password = ''.obs;

  @override
  void onInit() {
    autoLoginAfterDeploy.value =
        storage.read(StorageKey.autoLoginAfterDeploy.name) ?? false;
    autoDeploy.value = (storage.read(StorageKey.autoDeploy.name) ?? false) &&
        PlatformUtils.isDesktop;
    address.value = storage.read(StorageKey.address.name) ?? '';
    username.value = storage.read(StorageKey.username.name) ?? '';
    password.value = storage.read(StorageKey.password.name) ?? '';

    initTemporaryDirectory();
    getCurrentVersion().then((value) {
      GlobalVar.version = value;
    });
    _syncApiAddress();
    super.onInit();
  }

  void initTemporaryDirectory() {
    temporaryDirectory = storage.read(StorageKey.temporaryDirectory.name) ??
        Directory.systemTemp.path;
    storage.write(StorageKey.temporaryDirectory.name, temporaryDirectory);
  }

  void updateAutoLoginAfterDeploy(bool nv) {
    autoLoginAfterDeploy.value = nv;
    storage.write(StorageKey.autoLoginAfterDeploy.name, nv);
  }

  void updateAutoDeploy(bool nv) {
    autoDeploy.value = nv;
    storage.write(StorageKey.autoDeploy.name, nv);
  }

  void updateAddress(String value) {
    address.value = value.trim();
    storage.write(StorageKey.address.name, address.value);
    _syncApiAddress();
  }

  void updateUsername(String value) {
    username.value = value.trim();
    storage.write(StorageKey.username.name, username.value);
  }

  void updatePassword(String value) {
    password.value = value;
    storage.write(StorageKey.password.name, password.value);
  }

  void _syncApiAddress() {
    if (address.value.isEmpty) {
      return;
    }
    final normalized = address.value.startsWith('http://') ||
            address.value.startsWith('https://')
        ? address.value
        : 'http://${address.value}';
    ApiClient().setAddress(normalized);
  }

  Future<void> killServer({bool showTip = true}) async {
    final success = await ApiClient().killServer();
    if (success) {
      if (showTip) {
        Get.snackbar(I18n.kill_server_success.tr, '');
      }
      await resetClient();
    } else if (showTip) {
      Get.snackbar(
          I18n.kill_server_failure.tr, I18n.kill_server_failure_msg.tr);
    }
  }

  Future<void> resetClient() async {
    return;
  }
}
