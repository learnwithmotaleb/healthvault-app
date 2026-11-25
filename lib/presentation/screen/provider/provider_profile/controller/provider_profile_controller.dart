import 'package:get/get.dart';

import '../../../../../data/models/user_models.dart';
import '../../../../../service/session_service.dart';

/// Provider account (GET /user/getMe).
class ProviderProfileController extends GetxController {
  final isLoading = false.obs;

  Rx<AccountModel?> get account => SessionService.account;
  ProfileModel? get profile => account.value?.profile;

  @override
  void onInit() {
    super.onInit();
    getProviderProfile();
  }

  Future<void> getProviderProfile() async {
    isLoading.value = account.value == null;
    await SessionService.refreshMe();
    isLoading.value = false;
  }
}
