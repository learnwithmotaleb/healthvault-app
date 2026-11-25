import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/responsive_layout/dimensions/dimensions.dart';
import '../../../../../core/routes/route_path.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/account_setting_controller.dart';
import '../widget/account_setting_widget.dart';

class AccountSettingScreen extends StatelessWidget {
  const AccountSettingScreen({super.key});

  Future<void> _confirmDelete(AccountSettingController c) async {
    final ok = await Dialogs.confirm(
      title: AppStrings.deleteAccount.tr,
      message: 'This cannot be undone. All your records and files will be permanently deleted.'.tr,
      confirmText: 'Continue'.tr,
      destructive: true,
    );
    if (!ok) return;
    final pass = TextEditingController();
    final password = await Get.dialog<String>(AlertDialog(
      title: Text('Confirm with your password'.tr),
      content: TextField(
        controller: pass,
        obscureText: true,
        decoration: InputDecoration(hintText: 'Password'.tr, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
        TextButton(
          onPressed: () => pass.text.isEmpty ? null : Get.back(result: pass.text),
          child: Text(AppStrings.deleteAccount.tr, style: const TextStyle(color: AppColors.emergencyColor)),
        ),
      ],
    ));
    if (password != null && password.isNotEmpty) c.deleteAccount(password);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AccountSettingController());
    Widget tile(IconData icon, String title, VoidCallback onTap, {Color? color}) => Padding(
          padding: EdgeInsets.only(bottom: Dimensions.h(12)),
          child: AccountSettingMenuTile(
            width: double.infinity,
            height: Dimensions.h(56),
            icon: icon,
            title: title,
            fontSize: 14,
            color: AppColors.whiteColor,
            iconColor: color ?? AppColors.primaryColor,
            textColor: color ?? AppColors.blackColor,
            onTap: onTap,
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.accountSetting.tr),
      body: Obx(() => ListView(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.w(16), vertical: 8),
            children: [
              tile(Icons.lock_outline, AppStrings.changePassword.tr, () => Get.toNamed(RoutePath.changePassword)),
              tile(Icons.notifications_active_outlined, 'Notification settings'.tr,
                  () => Get.toNamed(RoutePath.notificationSettings)),
              tile(Icons.language, AppStrings.language.tr, () => Get.toNamed(RoutePath.changeLanguageProfile)),
              tile(
                Icons.download_outlined,
                c.isExporting.value ? 'Preparing…'.tr : 'Download my data'.tr,
                c.isExporting.value ? () {} : c.exportData,
              ),
              tile(Icons.person_remove_outlined, AppStrings.deleteAccount.tr, () => _confirmDelete(c),
                  color: AppColors.emergencyColor),
              if (c.isLoading.value) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Text('You can download a copy of all data stored about you at any time (GDPR).'.tr,
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
            ],
          )),
    );
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<AccountSettingController>() ? Get.find<AccountSettingController>() : Get.put(AccountSettingController());
    Widget sw(String key, String title, String subtitle, bool value) => SwitchListTile(
          activeThumbColor: AppColors.primaryColor,
          title: Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
          value: value,
          onChanged: (v) => c.setPreference(key, v),
        );
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'Notification settings'.tr),
      body: Obx(() {
        final p = c.prefs.value;
        return ListView(children: [
          sw('appointments', 'Appointments'.tr, 'Requests, updates and 24-hour reminders'.tr, p.appointments),
          sw('reminders', 'Medication reminders'.tr, 'A push at each dose time'.tr, p.reminders),
          sw('insurance', 'Insurance'.tr, 'Expiry reminders'.tr, p.insurance),
          sw('general', 'General'.tr, 'Announcements, document review, support replies'.tr, p.general),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Turning a category off only stops push alerts. You will still see it in Notifications.'.tr,
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
          ),
        ]);
      }),
    );
  }
}
