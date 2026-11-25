import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/route_path.dart';
import '../../utils/app_colors/app_colors.dart';
import '../../utils/app_text_style/app_text_style.dart';

/// GDPR consent checkbox with a link to the privacy policy.
class PrivacyConsent extends StatelessWidget {
  final RxBool value;
  const PrivacyConsent({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value.value,
              activeColor: AppColors.primaryColor,
              onChanged: (v) => value.value = v ?? false,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                    children: [
                      TextSpan(text: "${'I have read and accept the'.tr} "),
                      TextSpan(
                        text: 'Privacy Policy'.tr,
                        style: const TextStyle(color: AppColors.primaryColor, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed(RoutePath.policy),
                      ),
                      TextSpan(text: " ${'and consent to the processing of my health data.'.tr}"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
