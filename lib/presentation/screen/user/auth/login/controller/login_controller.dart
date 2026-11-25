import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/routes/route_path.dart';
import '../../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../../service/api_service.dart';
import '../../../../../../service/api_url.dart';
import '../../../../../../service/session_service.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  var isPasswordHidden = true.obs;
  var isLoading = false.obs;

  final formKey = GlobalKey<FormState>();

  void togglePassword() => isPasswordHidden.value = !isPasswordHidden.value;

  /// POST /auth/login
  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    final email = emailController.text.trim().toLowerCase();

    isLoading.value = true;
    final res = await ApiClient().post(
      url: ApiUrl.userLogin,
      isToken: false,
      body: {
        "email": email,
        "password": passwordController.text,
        if (SessionService.playerId != null) "playerId": SessionService.playerId,
      },
    );
    isLoading.value = false;

    if (res.isOk && res.data is Map) {
      await SessionService.saveAuth(Map<String, dynamic>.from(res.data));
      AppSnackBar.success("Login Successful", title: "Health Vault");
      SessionService.goHome();
      return;
    }

    // Email not verified → send a new code and open the OTP screen.
    if (res.statusCode == 403 && res.message.toLowerCase().contains('verif')) {
      AppSnackBar.info(res.message, title: "Health Vault");
      await ApiClient().post(url: ApiUrl.resendOtp, isToken: false, body: {"email": email, "purpose": "verify"});
      Get.toNamed(RoutePath.verification, arguments: {"email": email});
      return;
    }

    AppSnackBar.fail(res.message, title: "Health Vault");
  }

  void forgotPassword() => Get.toNamed(RoutePath.forget);

  void signup() => Get.toNamed(RoutePath.signup);

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }
}
