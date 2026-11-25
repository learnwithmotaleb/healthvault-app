import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'global/language/controller/language_controller.dart';
import 'helper/device_utils/device_utils.dart';
import 'helper/local_db/local_db.dart';
import 'helper/no_internet/controller/no_internet_controller.dart';
import 'presentation/screen/provider/doctor_identification/controller/service_selection_controller.dart';
import 'service/session_service.dart';
import 'service/socket_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage first – language, tokens and role are read from it.
  await SharePrefsHelper.init();
  await initializeDateFormatting('en');
  await initializeDateFormatting('el');

  final languageController = Get.put(LanguageController(), permanent: true);
  await languageController.loadLanguage();

  DeviceUtils.lockDevicePortrait();
  Get.put(ServiceSelectionController(), permanent: true);
  Get.put(InternetController(), permanent: true);
  Get.put(RealtimeService(), permanent: true);

  if (SessionService.isLoggedIn) {
    RealtimeService.to.connect();
    SessionService.refreshMe(); // refresh cached profile in the background
  }

  runApp(MyApp());
}
