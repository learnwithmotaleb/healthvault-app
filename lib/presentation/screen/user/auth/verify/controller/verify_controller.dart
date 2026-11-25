import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../../../core/routes/route_path.dart';
import '../../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../../service/api_service.dart';
import '../../../../../../service/api_url.dart';
import '../../forget/controller/forget_controller.dart';

/// Step 2 of forgot password → POST /auth/verify-otp
class VerifyController extends GetxController {
  final otpController = TextEditingController();
  RxBool isLoading = false.obs;
  RxBool isLoadingResend = false.obs;

  String email = '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['email'] != null) {
      email = args['email'].toString();
    } else if (Get.isRegistered<ForgetController>()) {
      email = Get.find<ForgetController>().email;
    }
  }

  Future<void> emailVerifyProcess() async {
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      AppSnackBar.fail("Please enter a valid 6-digit code", title: "OTP verification");
      return;
    }
    isLoading.value = true;
    final res = await ApiClient().post(url: ApiUrl.verifyOtp, isToken: false, body: {"email": email, "otp": otp});
    isLoading.value = false;

    if (res.isOk) {
      AppSnackBar.success(res.data is Map ? (res.data['message'] ?? res.message) : res.message, title: "OTP verified");
      Get.toNamed(RoutePath.reset, arguments: {"email": email});
    } else {
      AppSnackBar.fail(res.message, title: "OTP verification");
    }
  }

  Future<void> resendOtpProcess() async {
    isLoadingResend.value = true;
    final res =
        await ApiClient().post(url: ApiUrl.resendOtp, isToken: false, body: {"email": email, "purpose": "reset"});
    isLoadingResend.value = false;
    res.isOk ? AppSnackBar.success("A new code has been sent") : AppSnackBar.fail(res.message);
  }

  @override
  void onClose() {
    // otpController is disposed by PinCodeTextField (autoDisposeControllers).
    super.onClose();
  }
}
