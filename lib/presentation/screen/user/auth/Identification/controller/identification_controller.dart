import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../signup/signup_flow.dart';

import '../../../../../../core/routes/route_path.dart';
import '../../../../../../global/language/controller/language_controller.dart';
import '../../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../../service/api_service.dart';
import '../../../../../../service/api_url.dart';
import '../../../../../../service/session_service.dart';
import '../../../../../widget/hv_ui.dart';
import '../../registaration/controller/registration_controller.dart';
import '../../signup/controller/signup_controller.dart';

/// Final patient sign-up step → POST /user/register (multipart `data` + profile_image).
class IdentificationController extends GetxController {
  final allergiesController = TextEditingController();
  final chronicController = TextEditingController();
  final contactNameController = TextEditingController();
  final contactRelationController = TextEditingController();

  final isLoading = false.obs;
  final acceptPrivacy = false.obs;
  final Rx<File?> photo = Rx<File?>(null);

  Future<void> pickFromGallery() async {
    final f = await FilePick.chooseSource(allowPdf: false);
    if (f.isNotEmpty) photo.value = f.first;
  }

  void removePhoto() => photo.value = null;

  Future<void> registration() async {
    if (!acceptPrivacy.value) {
      AppSnackBar.fail("Please accept the privacy policy to continue");
      return;
    }
    final signup = Get.find<SignupController>();
    final reg = Get.find<RegistrationController>();

    final dob = reg.dateOfBirthController.text.trim();
    final gender = reg.selectedGender.value.isNotEmpty
        ? reg.selectedGender.value
        : reg.genderController.text.trim().toUpperCase();
    final blood = reg.bloodGroupController.text.trim().toUpperCase();
    final emergencyPhone = reg.emergencyContactController.text.trim();
    final isEnglish = Get.isRegistered<LanguageController>() ? Get.find<LanguageController>().isEnglish.value : true;

    final data = <String, dynamic>{
      "role": "NORMALUSER",
      "fullName": reg.fullNameController.text.trim().isNotEmpty ? reg.fullNameController.text.trim() : signup.name.value,
      "email": signup.email.value.trim().toLowerCase(),
      "password": signup.password.value,
      "phone": signup.phone.value.trim(),
      "dateOfBirth": dob.length >= 10 ? dob.substring(0, 10) : dob,
      "gender": gender,
      "bloodGroup": blood,
      "acceptPrivacyPolicy": true,
      "language": isEnglish ? "en" : "el",
      if (reg.addressController.text.trim().isNotEmpty) "address": reg.addressController.text.trim(),
      if (reg.membershipIDController.text.trim().isNotEmpty) "membershipId": reg.membershipIDController.text.trim(),
      if (reg.identificationController.text.trim().isNotEmpty)
        "identificationNumber": reg.identificationController.text.trim(),
      if (emergencyPhone.isNotEmpty) ...{
        "emergencyContact": emergencyPhone,
        "emergencyContacts": [
          {
            "name": contactNameController.text.trim().isNotEmpty ? contactNameController.text.trim() : "Emergency contact",
            "phone": emergencyPhone,
            if (contactRelationController.text.trim().isNotEmpty) "relation": contactRelationController.text.trim(),
          }
        ],
      },
      if (splitCsv(allergiesController.text).isNotEmpty) "allergies": splitCsv(allergiesController.text),
      if (splitCsv(chronicController.text).isNotEmpty) "chronicConditions": splitCsv(chronicController.text),
      if (SessionService.playerId != null) "playerId": SessionService.playerId,
    };

    isLoading.value = true;
    final res = await ApiClient().sendForm(
      url: ApiUrl.userRegister,
      data: data,
      isToken: false,
      files: [if (photo.value != null) MultipartFileData(key: "profile_image", path: photo.value!.path)],
    );
    isLoading.value = false;

    if (res.isOk) {
      AppSnackBar.success(res.message);
      final emailSent = res.data is Map ? res.data['emailSent'] != false : true;
      Get.offAllNamed(RoutePath.verification, arguments: {"email": data['email'], "emailSent": emailSent});
      Future.delayed(const Duration(milliseconds: 600), SignupFlow.clear);
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  @override
  void onClose() {
    allergiesController.dispose();
    chronicController.dispose();
    contactNameController.dispose();
    contactRelationController.dispose();
    super.onClose();
  }
}
