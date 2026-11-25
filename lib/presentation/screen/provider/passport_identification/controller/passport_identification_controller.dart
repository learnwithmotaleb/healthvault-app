import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../user/auth/signup/signup_flow.dart';
import 'package:healthvault/helper/local_db/local_db.dart';
import 'package:healthvault/presentation/screen/category_screen/pharmacy/controller/pharmacy_controller.dart';
import 'package:healthvault/presentation/screen/provider/doctor_identification/controller/doctor_indentification_controller.dart';
import 'package:healthvault/presentation/screen/provider/medical_license/controller/medical_license_controller.dart';
import 'package:healthvault/presentation/screen/provider/pharmacy_identification/controller/pharmacy_identification_controller.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../helper/role_controller/role_controller.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../../service/session_service.dart';
import '../../../../../global/language/controller/language_controller.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../widget/hv_ui.dart';
import '../../../user/auth/registaration/controller/registration_controller.dart';
import '../../../user/auth/signup/controller/signup_controller.dart';
import '../../doctor_identification/controller/service_selection_controller.dart';

class PassportIdentificationController extends GetxController {

  late DoctorIdentificationController doctorController;
  late PharmacyIdentificationController pharmacyController = Get.put(PharmacyIdentificationController());


  late final String name;
  late final String email;
  late final String phone;
  late final String password;

  late final String providerTypeId;
  late final String providerTypeKey;
  late final String providerTypeLabel;
  XFile? profilePhoto; // final photo file
  Rx<XFile?> photoForIdentification =Rx<XFile?>(null);


  late final String serviceId;
  late final String serviceTitle;
  late final String servicePrice;

  AppRole? role;

  String other = "OTHER";




  //=======================================================
  /// Pick image from gallery
  Future<void> pickFromGallery() async {
    try {
      final result = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (result != null) photoForIdentification.value = result;
    } catch (e) {
      Get.snackbar("Error", "Failed to pick image: $e");
    }
  }

  /// Remove selected photo
  void removePhoto() => photoForIdentification.value = null;
  //=======================================================


  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadRole();
    // ✅ Get the existing controller instead of creating a new one
    doctorController = Get.isRegistered<DoctorIdentificationController>()
        ? Get.find<DoctorIdentificationController>()
        : Get.put(DoctorIdentificationController(Get.find<SignupController>().selectedProviderKey.value));
    pharmacyController = Get.isRegistered<PharmacyIdentificationController>()
        ? Get.find<PharmacyIdentificationController>()
        : Get.put(PharmacyIdentificationController());
    
    
    final signupCtrl = Get.find<SignupController>();
    final medicalCtrl = Get.find<MedicalLicenseController>();
    final serviceCtrl = Get.find<ServiceSelectionController>();



    name = signupCtrl.name.value;
    email = signupCtrl.email.value;
    phone = signupCtrl.phone.value;
    password = signupCtrl.password.value;

    providerTypeId = signupCtrl.selectedProviderId.value;
    providerTypeKey = signupCtrl.selectedProviderKey.value;
    providerTypeLabel = signupCtrl.selectedProviderLabel.value;

    /// Receive image from MedicalLicenseController
    profilePhoto = medicalCtrl.photo.value;


    //===============


    print("---- RECEIVED FROM SIGNUP ----");
    print("Name: $name");
    print("Email: $email");
    print("Phone: $phone");
    print("Password: $password");
    print("Provider ID: $providerTypeId");
    print("Provider Key: $providerTypeKey");
    print("Provider Label: $providerTypeLabel");
    print("Profile Photo Instance: ${profilePhoto?.path.toString()}");
    print("Identification Photo Instance: ${photoForIdentification.toString()}");

    // ⭐ Now read service info
    serviceId = serviceCtrl.serviceId.value;
    serviceTitle = serviceCtrl.serviceTitle.value;
    servicePrice = serviceCtrl.servicePrice.value;

    print("===== SERVICE RECEIVED =====");
    print("Service ID: $serviceId");
    print("Service Title: $serviceTitle");
    print("Service Price: $servicePrice");
    print("Role: =========================== $role");


  }

  Future<void> loadRole() async {
    final r = await RoleController().getRole();
    role = r;

    print("================== ROLE LOADED ==================");
    print("Role from local storage: ${role?.name}");
    print("=================================================");
  }


  /// Image picker
  final ImagePicker _picker = ImagePicker();

  final acceptPrivacy = false.obs;

  /// POST /user/register (multipart: data + identification_images + profile_image)
  Future<void> registration() async {
    if (photoForIdentification.value == null) {
      AppSnackBar.fail("Please upload an identification document first");
      return;
    }
    if (!acceptPrivacy.value) {
      AppSnackBar.fail("Please accept the privacy policy to continue");
      return;
    }

    final isDoctor = providerTypeKey.toUpperCase() == "DOCTOR";
    final isEnglish = Get.isRegistered<LanguageController>() ? Get.find<LanguageController>().isEnglish.value : true;

    final Map<String, dynamic> data = {
      "role": "PROVIDER",
      "fullName": name.trim(),
      "email": email.trim().toLowerCase(),
      "password": password,
      "phone": phone.trim(),
      "providerTypeId": providerTypeId,
      "acceptPrivacyPolicy": true,
      "language": isEnglish ? "en" : "el",
      if (serviceId.isNotEmpty) "serviceId": [serviceId],
      if (SessionService.playerId != null) "playerId": SessionService.playerId,
    };

    if (isDoctor) {
      final d = doctorController;
      final address = d.addressController.text.trim();
      data.addAll({
        "specialization": d.specialisationsController.text.trim(),
        "medicalLicenseNumber": d.medicalLicenseNumberController.text.trim(),
        if (d.idOrPassPortNumberController.text.trim().isNotEmpty)
          "identificationNumber": d.idOrPassPortNumberController.text.trim(),
        if (int.tryParse(d.yearOfExperienceController.text.trim()) != null)
          "yearsOfExperience": int.parse(d.yearOfExperienceController.text.trim()),
        if (splitCsv(d.languagesSpokenController.text).isNotEmpty) "languages": splitCsv(d.languagesSpokenController.text),
        if (address.isNotEmpty) "address": address,
        if (address.isNotEmpty) "location": address.split(',').last.trim(),
        if (d.aboutController.text.trim().isNotEmpty) "about": d.aboutController.text.trim(),
      });
    } else {
      final p = pharmacyController;
      final address = p.addressController.text.trim();
      data.addAll({
        if (p.nameController.text.trim().isNotEmpty) "displayName": p.nameController.text.trim(),
        if (p.businessRegisterNumberController.text.trim().isNotEmpty)
          "businessRegistrationNumber": p.businessRegisterNumberController.text.trim(),
        if (p.drugLicenseNumberController.text.trim().isNotEmpty)
          "drugLicenseNumber": p.drugLicenseNumberController.text.trim(),
        if (address.isNotEmpty) "address": address,
        if (address.isNotEmpty) "location": address.split(',').last.trim(),
        if (p.aboutController.text.trim().isNotEmpty) "about": p.aboutController.text.trim(),
      });
    }

    isLoading.value = true;
    final res = await ApiClient().sendForm(
      url: ApiUrl.userRegister,
      isToken: false,
      data: data,
      files: [
        MultipartFileData(key: "identification_images", path: photoForIdentification.value!.path),
        if (profilePhoto != null) MultipartFileData(key: "profile_image", path: profilePhoto!.path),
      ],
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
}
