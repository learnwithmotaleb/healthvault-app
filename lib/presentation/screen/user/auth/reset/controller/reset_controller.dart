import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:healthvault/presentation/screen/user/auth/forget/controller/forget_controller.dart';
import '../../../../../../core/routes/route_path.dart';
import '../../../../../../helper/local_db/local_db.dart';
import '../../../../../../helper/local_db/shareprefs_helper.dart';
import '../../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../../service/api_service.dart';
import '../../../../../../service/api_url.dart';
import '../../../../../../service/session_service.dart';

class ResetController extends GetxController {
  /// Text controllers
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  /// Focus nodes
  final newPasswordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();


  var isNewPasswordHidden = true.obs;
  var isConfirmPasswordHidden = true.obs;

  /// Loading state
  var isLoading = false.obs;

  /// Form key
  final formKey = GlobalKey<FormState>();

  void toggleNewPassword() => isNewPasswordHidden.value = !isNewPasswordHidden.value;
  void toggleConfirmPassword() => isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;

  /// Step 3 of forgot password → POST /auth/reset-password → tokens (logged in)
  Future<void> resetPassword() async {
    newPasswordFocus.unfocus();
    confirmPasswordFocus.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;

    final newPassword = newPasswordController.text;
    if (newPassword.length < 8) {
      AppSnackBar.fail("Password must be at least 8 characters", title: "Reset Password");
      return;
    }
    if (newPassword != confirmPasswordController.text) {
      AppSnackBar.fail("New password and confirm password do not match", title: "Health Vault");
      return;
    }

    String email = '';
    final args = Get.arguments;
    if (args is Map && args['email'] != null) email = args['email'].toString();
    if (email.isEmpty && Get.isRegistered<ForgetController>()) email = Get.find<ForgetController>().email;

    isLoading.value = true;
    final res = await ApiClient().post(
      url: ApiUrl.resetPassword,
      isToken: false,
      body: {"email": email, "newPassword": newPassword},
    );

    if (res.isOk && res.data is Map) {
      await SessionService.saveAuth(Map<String, dynamic>.from(res.data));
      await SessionService.refreshMe();
      isLoading.value = false;
      AppSnackBar.success("Password reset successfully", title: "Health Vault");
      if (SessionService.role.isNotEmpty) {
        SessionService.goHome();
      } else {
        Get.offAllNamed(RoutePath.login);
      }
    } else {
      isLoading.value = false;
      AppSnackBar.fail(res.message, title: "Reset Password");
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    newPasswordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.onClose();
  }
}
