import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../data/models/user_models.dart';
import '../../../../../helper/local_db/local_db.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../../service/session_service.dart';
import '../../../../../service/socket_service.dart';

class AccountSettingController extends GetxController {
  final _api = ApiClient();
  final isLoading = false.obs;
  final isExporting = false.obs;

  // notification preferences
  final prefs = NotificationPreferences().obs;
  final isSavingPrefs = false.obs;

  @override
  void onInit() {
    super.onInit();
    final acc = SessionService.account.value;
    if (acc != null) prefs.value = acc.notificationPreferences;
  }

  /// PATCH /user/settings
  Future<void> setPreference(String key, bool value) async {
    final p = prefs.value;
    switch (key) {
      case 'appointments':
        p.appointments = value;
      case 'reminders':
        p.reminders = value;
      case 'insurance':
        p.insurance = value;
      case 'general':
        p.general = value;
    }
    prefs.refresh();
    isSavingPrefs.value = true;
    final res = await _api.patch(url: ApiUrl.settings, body: {
      "notificationPreferences": {key: value},
    });
    isSavingPrefs.value = false;
    if (res.isOk) {
      SessionService.refreshMe();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  /// GET /user/export-my-data → .json file → share sheet
  Future<void> exportData() async {
    isExporting.value = true;
    final res = await _api.get(url: ApiUrl.exportMyData);
    isExporting.value = false;
    if (!res.isOk) return AppSnackBar.fail(res.message);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/health-vault-my-data-$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(res.data ?? res.body));
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      subject: 'Health Vault – my data',
    ));
  }

  /// DELETE /auth/delete-me { password }
  Future<void> deleteAccount(String password) async {
    isLoading.value = true;
    final res = await _api.delete(url: ApiUrl.deleteAccount, body: {"password": password});
    isLoading.value = false;
    if (res.isOk) {
      RealtimeService.to.disconnect();
      await SharePrefsHelper.clearSession();
      SessionService.account.value = null;
      AppSnackBar.success("Your account and all related data were permanently deleted", title: "Health Vault");
      Get.offAllNamed(RoutePath.select);
    } else {
      AppSnackBar.fail(res.message, title: "Health Vault");
    }
  }
}
