import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/routes/route_path.dart';
import '../../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../../service/api_service.dart';
import '../../../../../../service/api_url.dart';

/// Step 1 of forgot password → POST /auth/forgot-password
class ForgetController extends GetxController {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var isLoading = false.obs;

  String get email => emailController.text.trim().toLowerCase();

  Future<void> sendCode() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    final res = await ApiClient().post(url: ApiUrl.forgetPassword, isToken: false, body: {"email": email});
    isLoading.value = false;

    if (res.isOk) {
      AppSnackBar.success(res.data is Map ? (res.data['message'] ?? res.message) : res.message, title: "Health Vault");
      Get.toNamed(RoutePath.verify, arguments: {"email": email});
    } else {
      AppSnackBar.fail(res.message, title: "Health Vault");
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
