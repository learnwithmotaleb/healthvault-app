import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healthvault/core/responsive_layout/dimensions/dimensions.dart';
import 'package:healthvault/utils/app_colors/app_colors.dart';
import 'package:healthvault/utils/static_strings/static_strings.dart';

import '../../../../../widget/hv_ui.dart';
import '../../../../../widget/privacy_consent.dart';
import '../controller/identification_controller.dart';

class IdentificationScreen extends StatelessWidget {
  IdentificationScreen({super.key});

  final IdentificationController controller = Get.isRegistered<IdentificationController>()
      ? Get.find<IdentificationController>()
      : Get.put(IdentificationController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        backgroundColor: AppColors.whiteColor,
        title: Text(AppStrings.proofOfIdentification.tr),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppStrings.uploadProfilePhoto.tr} (${'optional'.tr})",
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: Dimensions.h(16)),
            Obx(() {
              final photo = controller.photo.value;
              return GestureDetector(
                onTap: photo == null ? controller.pickFromGallery : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryColor),
                        boxShadow: const [BoxShadow(color: AppColors.greyColor, blurRadius: 2, offset: Offset(0, 2))],
                      ),
                      child: photo == null
                          ? const Center(child: Icon(Icons.add_a_photo_outlined, color: Colors.black54, size: 28))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(photo, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                    ),
                    if (photo != null)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: GestureDetector(
                          onTap: controller.removePhoto,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            SizedBox(height: Dimensions.h(24)),
            LabeledField(
              label: 'Emergency contact name'.tr,
              controller: controller.contactNameController,
              hint: 'e.g. Nikos Papadopoulos',
            ),
            LabeledField(
              label: 'Relation'.tr,
              controller: controller.contactRelationController,
              hint: 'e.g. Brother',
            ),
            LabeledField(
              label: 'Allergies'.tr,
              controller: controller.allergiesController,
              hint: 'penicillin, nuts',
            ),
            LabeledField(
              label: 'Chronic conditions'.tr,
              controller: controller.chronicController,
              hint: 'asthma, diabetes',
            ),
            const SizedBox(height: 4),
            PrivacyConsent(value: controller.acceptPrivacy),
            SizedBox(height: Dimensions.h(24)),
            Obx(() => PrimaryButton(
                  label: AppStrings.next.tr,
                  loading: controller.isLoading.value,
                  onPressed: controller.registration,
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
