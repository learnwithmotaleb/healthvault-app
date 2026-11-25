import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../service/session_service.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/file_viewer.dart';
import '../../../../widget/hv_ui.dart';
import '../../../profile/profile/widget/profile_menu_item.dart';
import '../controller/provider_profile_controller.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<ProviderProfileController>()
        ? Get.find<ProviderProfileController>()
        : Get.put(ProviderProfileController());
    const gap = SizedBox(height: 10);

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.profile.tr, showBack: Navigator.of(context).canPop()),
      body: Obx(() {
        final acc = c.account.value;
        final p = c.profile;
        if (c.isLoading.value && acc == null) return const Center(child: CircularProgressIndicator());
        if (acc == null) return ErrorView(message: 'Could not load your profile'.tr, onRetry: c.getProviderProfile);
        return RefreshIndicator(
          onRefresh: c.getProviderProfile,
          child: ListView(padding: const EdgeInsets.all(10), children: [
            HVCardBox(
              child: Column(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Avatar(image: p?.profileImage, name: acc.displayName, radius: 38),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(acc.displayName, style: AppTextStyles.title),
                      if ((p?.specialization ?? '').isNotEmpty)
                        Text(p!.specialization!, style: AppTextStyles.body.copyWith(color: AppColors.primaryColor)),
                      Text(Fmt.enumLabel(p?.providerType?.label ?? ''),
                          style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                      const SizedBox(height: 6),
                      StatusChip(p?.approvalStatus ?? 'PENDING'),
                    ]),
                  ),
                ]),
                const Divider(height: 24),
                KeyValueRow('Email'.tr, acc.email),
                KeyValueRow('Phone'.tr, acc.phone ?? ''),
                if ((p?.address ?? '').isNotEmpty) KeyValueRow('Address'.tr, p!.address!),
                if ((p?.location ?? '').isNotEmpty) KeyValueRow('City / area'.tr, p!.location!),
                if (p?.yearsOfExperience != null) KeyValueRow('Experience'.tr, "${p!.yearsOfExperience} ${'years'.tr}"),
                if ((p?.languages ?? []).isNotEmpty) KeyValueRow('Languages'.tr, p!.languages.join(', ')),
                if ((p?.medicalLicenseNumber ?? '').isNotEmpty) KeyValueRow('License no.'.tr, p!.medicalLicenseNumber!),
                if (p?.approvalStatus == 'REJECTED' && (p?.rejectionReason ?? '').isNotEmpty)
                  KeyValueRow('Rejection reason'.tr, p!.rejectionReason!),
                if ((p?.about ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerLeft, child: Text(p!.about!, style: AppTextStyles.body.copyWith(color: AppColors.labelColor))),
                ],
                if ((p?.identificationImages ?? '').isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => FileViewer.open(p!.identificationImages!, title: 'Identification'.tr),
                      icon: const Icon(Icons.badge_outlined),
                      label: Text('View identification document'.tr),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColor),
                    onPressed: () => Get.toNamed(RoutePath.editProfile),
                    child: Text(AppStrings.editProfile.tr),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            ProfileMenuTile(icon: Icons.medical_services_outlined, title: 'My services'.tr, onTap: () => Get.toNamed(RoutePath.providerService)),
            gap,
            ProfileMenuTile(icon: Icons.schedule, title: 'Weekly availability'.tr, onTap: () => Get.toNamed(RoutePath.providerSchedule)),
            gap,
            ProfileMenuTile(icon: Icons.notifications, title: AppStrings.notification.tr, onTap: () => Get.toNamed(RoutePath.notification)),
            gap,
            ProfileMenuTile(icon: Icons.support_agent, title: 'Support chat'.tr, onTap: () => Get.toNamed(RoutePath.supportChat)),
            gap,
            ProfileMenuTile(icon: Icons.settings, title: AppStrings.accountSetting.tr, onTap: () => Get.toNamed(RoutePath.accountSetting)),
            gap,
            ProfileMenuTile(icon: Icons.language, title: AppStrings.language.tr, onTap: () => Get.toNamed(RoutePath.changeLanguageProfile)),
            gap,
            ProfileMenuTile(icon: Icons.info_outline, title: 'About us'.tr, onTap: () => Get.toNamed(RoutePath.aboutUs)),
            gap,
            ProfileMenuTile(icon: Icons.library_books_sharp, title: AppStrings.termsAndCondition.tr, onTap: () => Get.toNamed(RoutePath.termsAndCondition)),
            gap,
            ProfileMenuTile(icon: Icons.question_mark_rounded, title: AppStrings.faq.tr, onTap: () => Get.toNamed(RoutePath.faq)),
            gap,
            ProfileMenuTile(icon: Icons.privacy_tip_outlined, title: AppStrings.privacyPolicy.tr, onTap: () => Get.toNamed(RoutePath.policy)),
            gap,
            ProfileMenuTile(
              icon: Icons.logout,
              title: AppStrings.logOut.tr,
              onTap: () async {
                if (await Dialogs.confirm(title: AppStrings.logOut.tr, message: AppStrings.areYouSureWantToLogOut.tr)) {
                  SessionService.logout();
                }
              },
            ),
            const SizedBox(height: 24),
          ]),
        );
      }),
    );
  }
}
