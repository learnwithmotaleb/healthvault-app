import 'package:get/get.dart';

import '../../../../../data/models/user_models.dart';
import '../../../../../service/api_url.dart';
import '../../../../../service/session_service.dart';

/// Current account (GET /user/getMe) for both roles.
class ProfileController extends GetxController {
  final isLoading = false.obs;
  final error = RxnString();

  Rx<AccountModel?> get account => SessionService.account;
  ProfileModel? get profile => account.value?.profile;

  bool get isProvider => SessionService.isProvider;
  bool get isNormalUser => SessionService.isPatient;
  String get role => SessionService.role;
  String get fullName => account.value?.displayName ?? '';
  String get fullImageUrl => ApiUrl.fileUrl(profile?.profileImage);

  @override
  void onInit() {
    super.onInit();
    getUserProfile();
  }

  Future<void> getUserProfile() async {
    isLoading.value = account.value == null;
    error.value = null;
    final acc = await SessionService.refreshMe();
    if (acc == null) error.value = 'Could not load your profile';
    isLoading.value = false;
  }

  Future<void> refreshProfile() => getUserProfile();
}
