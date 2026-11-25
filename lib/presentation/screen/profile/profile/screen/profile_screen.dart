import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/responsive_layout/dimensions/dimensions.dart';
import '../../../../../core/routes/route_path.dart';
import '../../../../../service/session_service.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../../../../widget/open_url.dart';
import '../controller/profile_controller.dart';
import '../simmer_effect/simmer_effect.dart';
import '../widget/infor_row_profile_widget.dart';
import '../widget/profile_menu_item.dart';
import '../widget/profile_section_title.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : Get.put(ProfileController());
    final gap = SizedBox(height: Dimensions.h(10));

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.profile.tr, showBack: Navigator.of(context).canPop()),
      body: Obx(() {
        final acc = controller.account.value;
        if (controller.isLoading.value && acc == null) return const ProfileScreenShimmer();
        if (acc == null) {
          return ErrorView(message: controller.error.value ?? 'Error'.tr, onRetry: controller.refreshProfile);
        }
        final profile = acc.profile;
        return RefreshIndicator(
          onRefresh: controller.refreshProfile,
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              HVCardBox(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Avatar(image: profile?.profileImage, name: acc.displayName, radius: 40),
                    SizedBox(width: Dimensions.w(16)),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(acc.displayName, style: AppTextStyles.title),
                        Text(acc.email, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                        SizedBox(height: Dimensions.h(6)),
                        if (controller.isProvider) ...[
                          if ((profile?.specialization ?? '').isNotEmpty)
                            InfoRowProfile(icon: Icons.medical_services, text: profile!.specialization!),
                          InfoRowProfile(icon: Icons.verified_user, text: Fmt.enumLabel(profile?.providerType?.label ?? '')),
                          StatusChip(profile?.approvalStatus ?? 'PENDING'),
                        ] else ...[
                          InfoRowProfile(icon: Icons.bloodtype, text: profile?.bloodGroup ?? '-'),
                          if (profile?.membershipId != null)
                            InfoRowProfile(icon: Icons.card_membership, text: "${'Member'.tr}: ${profile!.membershipId}"),
                          if (profile?.gender != null) InfoRowProfile(icon: Icons.person, text: Fmt.enumLabel(profile!.gender!)),
                        ],
                        if ((profile?.address ?? '').isNotEmpty)
                          InfoRowProfile(icon: Icons.location_on, text: profile!.address!),
                      ]),
                    ),
                  ]),
                  SizedBox(height: Dimensions.h(8)),
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
              SizedBox(height: Dimensions.h(20)),
              if (controller.isNormalUser) ...[
                ProfileMenuTile(icon: Icons.credit_card, title: AppStrings.healthCardID.tr, onTap: () => Get.toNamed(RoutePath.healthCard)),
                gap,
                ProfileMenuTile(icon: Icons.folder_shared_outlined, title: AppStrings.document.tr, onTap: () => Get.toNamed(RoutePath.document)),
                gap,
                ProfileMenuTile(icon: Icons.fact_check_rounded, title: AppStrings.insurance.tr, onTap: () => Get.toNamed(RoutePath.insurance)),
                gap,
                ProfileMenuTile(icon: Icons.monitor_heart_outlined, title: AppStrings.healthLogs.tr, onTap: () => Get.toNamed(RoutePath.healthLog)),
                gap,
                ProfileMenuTile(icon: Icons.favorite, title: AppStrings.favourite.tr, onTap: () => Get.toNamed(RoutePath.favourite)),
                gap,
                ProfileMenuTile(icon: Icons.sos_outlined, title: AppStrings.emergency.tr, onTap: () => Get.toNamed(RoutePath.emergency)),
                gap,
                ProfileMenuTile(
                  icon: Icons.health_and_safety_rounded,
                  title: AppStrings.myHealth.tr,
                  onTap: () => openExternalUrl("https://citizen.ehealthrecord.gov.gr/auth/signin"),
                ),
                gap,
              ],
              ProfileMenuTile(icon: Icons.notifications, title: AppStrings.notification.tr, onTap: () => Get.toNamed(RoutePath.notification)),
              gap,
              ProfileMenuTile(icon: Icons.support_agent, title: 'Support chat'.tr, onTap: () => Get.toNamed(RoutePath.supportChat)),
              gap,
              ProfileMenuTile(icon: Icons.settings, title: AppStrings.accountSetting.tr, onTap: () => Get.toNamed(RoutePath.accountSetting)),
              gap,
              ProfileMenuTile(icon: Icons.language, title: AppStrings.language.tr, onTap: () => Get.toNamed(RoutePath.changeLanguageProfile)),
              SizedBox(height: Dimensions.h(16)),
              ProfileSectionTitle(title: AppStrings.more.tr),
              SizedBox(height: Dimensions.h(12)),
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
              SizedBox(height: Dimensions.h(30)),
            ],
          ),
        );
      }),
    );
  }
}
