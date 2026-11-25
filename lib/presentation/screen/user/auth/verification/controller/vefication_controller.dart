import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../../service/api_service.dart';
import '../../../../../../service/api_url.dart';
import '../../../../../../service/session_service.dart';
import '../../signup/controller/signup_controller.dart';

/// Sign-up email verification → POST /auth/verify-email-otp (auto login).
class VerificationController extends GetxController {
  final otpController = TextEditingController();
  final otpFocus = FocusNode();

  RxBool isLoading = false.obs;
  RxBool isLoadingResend = false.obs;
  late final String email;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    String e = '';
    if (args is Map && args['email'] != null) e = args['email'].toString();
    if (e.isEmpty && Get.isRegistered<SignupController>()) {
      e = Get.find<SignupController>().emailController.text;
    }
    email = e.trim().toLowerCase();
    if (args is Map && args['emailSent'] == false) {
      Future.delayed(const Duration(milliseconds: 600),
          () => AppSnackBar.info("We couldn't send the code. Tap \"Resend\" to try again."));
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      AppSnackBar.fail("Please enter a valid 6-digit code", title: "Health Vault");
      return;
    }
    isLoading.value = true;
    final res = await ApiClient().post(
      url: ApiUrl.verifyEmailOtp,
      isToken: false,
      body: {"email": email, "otp": otp},
    );
    isLoading.value = false;

    if (res.isOk && res.data is Map) {
      AppSnackBar.success(res.message, title: "Health Vault");
      await SessionService.saveAuth(Map<String, dynamic>.from(res.data));
      SessionService.goHome();
    } else {
      AppSnackBar.fail(res.message, title: "OTP verification");
    }
  }

  Future<void> resendOtpProcess() async {
    isLoadingResend.value = true;
    final res = await ApiClient().post(
      url: ApiUrl.resendOtp,
      isToken: false,
      body: {"email": email, "purpose": "verify"},
    );
    isLoadingResend.value = false;
    if (res.isOk) {
      AppSnackBar.success(res.data is Map ? (res.data['message'] ?? res.message) : res.message);
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  @override
  void onClose() {
    // otpController is disposed by PinCodeTextField (autoDisposeControllers).
    // otpFocus is disposed by PinCodeTextField.
    super.onClose();
  }
}
