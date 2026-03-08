part of 'api_client.dart';

extension ApiClientFeedbackX on ApiClient {
  void showDialog(String title, String content) {
    Get.snackbar(title, content);
  }

  void showNetErrSnackBar() {
    Get.snackbar(
      I18n.networkError.tr,
      I18n.networkConnectTimeout.tr,
      duration: const Duration(seconds: 5),
    );
  }

  void showNetErrCodeSnackBar(String msg, int code) {
    Get.snackbar(
      I18n.networkError.tr,
      '${I18n.networkErrorCode.tr}: $code | $msg',
      duration: const Duration(seconds: 5),
    );
  }
}
