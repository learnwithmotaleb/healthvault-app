import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../../../service/session_service.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../helper/local_db/local_db.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';

class ChangePasswordController extends GetxController {
  final typePasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final typePasswordFocus = FocusNode();
  final newPasswordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  final formKey = GlobalKey<FormState>();

  var isLoading = false.obs;

  final isCurrentPasswordHidden = true.obs;
  final isNewPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;

  void toggleCurrentPassword() => isCurrentPasswordHidden.toggle();
  void toggleNewPassword() => isNewPasswordHidden.toggle();
  void toggleConfirmPassword() => isConfirmPasswordHidden.toggle();

  /// POST /auth/change-password → new tokens (old ones stop working)
  Future<void> changePassword() async {
    typePasswordFocus.unfocus();
    newPasswordFocus.unfocus();
    confirmPasswordFocus.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;

    final newPassword = newPasswordController.text;
    if (newPassword.length < 8) {
      AppSnackBar.fail("Password must be at least 8 characters");
      return;
    }
    if (newPassword != confirmPasswordController.text) {
      AppSnackBar.fail("New password and confirm password do not match");
      return;
    }

    isLoading.value = true;
    final res = await ApiClient().post(
      url: ApiUrl.changePassword,
      body: {"oldPassword": typePasswordController.text, "newPassword": newPassword},
    );
    isLoading.value = false;

    if (res.isOk) {
      if (res.data is Map) await SessionService.saveAuth(Map<String, dynamic>.from(res.data));
      AppSnackBar.success(res.message);
      Get.back();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  @override
  void onClose() {
    typePasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    typePasswordFocus.dispose();
    newPasswordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.onClose();
  }
}
