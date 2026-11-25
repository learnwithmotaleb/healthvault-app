
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/routes/route_path.dart';
import 'core/routes/routes.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/theme_controller.dart';
import 'global/language/controller/language_controller.dart';
import 'helper/no_internet/screen/no_internet_screen.dart';

class MyApp extends StatelessWidget {
  MyApp({super.key}) {
    Get.put(ThemeController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final LanguageController lc = Get.find<LanguageController>();


    return Obx(() {
      final themeMode = themeController.initialized
          ? themeController.mode.value
          : ThemeMode.system;

      Locale locale = lc.isEnglish.value
          ? const Locale('en', 'US')
          : const Locale('el', 'GR');


      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,

        translations: Language(),
        locale: locale,
        // English is the source language: any text without a translation
        // shows in English, never in the other language.
        fallbackLocale: const Locale('en', 'US'),
        supportedLocales: const [Locale('en', 'US'), Locale('el', 'GR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        getPages: AppRouter.pages,
        initialRoute: RoutePath.splash,
        // home:  ComponentsShowcasePage(), // or your initial screen

        // 🔥 IMPORTANT: Wrap entire app
        builder: (context, child) {
          return InternetWrapper(
            child: child ?? const SizedBox(),
          );
        },
      );
    });
  }
}

