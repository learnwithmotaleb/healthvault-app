import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../helper/local_db/local_db.dart';
import '../../../service/api_service.dart';
import '../../../service/api_url.dart';
import '../../../utils/app_const/app_const.dart';
import '../eng/eng.dart';
import '../greek/greek.dart';
import '../greek/greek_app.dart';

class Language extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    "en_US": english,
    "el_GR": {...greekApp, ...greek},
  };
}

class LanguageController extends GetxController {
  static LanguageController get to => Get.find();

  RxBool isEnglish = true.obs;

  // Load saved language
  Future<void> loadLanguage() async {
    isEnglish.value =
        await SharePrefsHelper.getBool(AppConstants.language) ?? true;
    _updateLocale();
  }

  // Switch language
  /// Also saves the choice on the server (PATCH /user/settings) when logged
  /// in, so push notifications arrive in the same language.
  Future<void> switchLanguage(bool englishSelected, {bool syncServer = true}) async {
    isEnglish.value = englishSelected;
    _updateLocale();
    await SharePrefsHelper.setBool(AppConstants.language, englishSelected);
    if (syncServer && (SharePrefsHelper.getToken() ?? '').isNotEmpty) {
      ApiClient().patch(url: ApiUrl.settings, body: {"language": englishSelected ? "en" : "el"});
    }
  }

  void _updateLocale() {
    if (isEnglish.value) {
      Get.updateLocale(const Locale("en", "US"));
    } else {
      Get.updateLocale(const Locale("el", "GR"));
    }
  }

}
