import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/json.dart';
import '../../../../../data/models/user_models.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../../service/session_service.dart';
import '../../../../widget/hv_ui.dart';

class ContactRow {
  final name = TextEditingController();
  final phone = TextEditingController();
  final relation = TextEditingController();

  ContactRow([EmergencyContact? c]) {
    if (c != null) {
      name.text = c.name;
      phone.text = c.phone;
      relation.text = c.relation ?? '';
    }
  }

  bool get isEmpty => name.text.trim().isEmpty && phone.text.trim().isEmpty;

  void dispose() {
    name.dispose();
    phone.dispose();
    relation.dispose();
  }
}

/// PATCH /user/updateMe (JSON or multipart data + profile_image)
class EditProfileController extends GetxController {
  final _api = ApiClient();
  final formKey = GlobalKey<FormState>();

  // common
  final nameController = TextEditingController();
  final numberController = TextEditingController();
  final addressController = TextEditingController();
  // patient
  final dateOfBirthController = TextEditingController();
  final genderController = TextEditingController();
  final identificationController = TextEditingController();
  final allergiesController = TextEditingController();
  final chronicController = TextEditingController();
  final gender = RxnString();
  final bloodGroup = RxnString();
  final dateOfBirth = Rxn<DateTime>();
  final contacts = <ContactRow>[].obs;
  // provider
  final displayNameController = TextEditingController();
  final aboutController = TextEditingController();
  final locationController = TextEditingController();
  final specializationController = TextEditingController();
  final experienceController = TextEditingController();
  final languagesController = TextEditingController();
  final catalogue = <ServiceModel>[].obs;
  final selectedServiceIds = <String>{}.obs;
  final ownServiceIds = <String>{};

  final Rx<File?> pickedImage = Rx<File?>(null);
  final existingImageUrl = ''.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  bool get isProvider => SessionService.isProvider;
  bool get isNormalUser => SessionService.isPatient;

  static const genders = ['MALE', 'FEMALE', 'OTHER'];
  static const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void onInit() {
    super.onInit();
    loadExistingProfile();
  }

  Future<void> loadExistingProfile() async {
    isLoading.value = true;
    final acc = await SessionService.refreshMe() ?? SessionService.account.value;
    final p = acc?.profile;
    if (acc != null) {
      nameController.text = p?.fullName.isNotEmpty == true ? p!.fullName : acc.fullName;
      numberController.text = acc.phone ?? '';
      addressController.text = p?.address ?? '';
      existingImageUrl.value = ApiUrl.fileUrl(p?.profileImage);
    }
    if (p != null && isNormalUser) {
      dateOfBirth.value = p.dateOfBirth;
      dateOfBirthController.text = p.dateOfBirth == null ? '' : Fmt.date(p.dateOfBirth);
      gender.value = p.gender;
      genderController.text = p.gender ?? '';
      bloodGroup.value = p.bloodGroup;
      identificationController.text = p.identificationNumber ?? '';
      allergiesController.text = p.allergies.join(', ');
      chronicController.text = p.chronicConditions.join(', ');
      final list = p.emergencyContacts.isNotEmpty
          ? p.emergencyContacts
          : ((p.emergencyContact ?? '').isNotEmpty ? [EmergencyContact(name: '', phone: p.emergencyContact!)] : <EmergencyContact>[]);
      contacts.assignAll(list.map(ContactRow.new));
    }
    if (p != null && isProvider) {
      displayNameController.text = p.displayName ?? '';
      aboutController.text = p.about ?? '';
      locationController.text = p.location ?? '';
      specializationController.text = p.specialization ?? '';
      experienceController.text = p.yearsOfExperience?.toString() ?? '';
      languagesController.text = p.languages.join(', ');
      selectedServiceIds
        ..clear()
        ..addAll(p.serviceIds.isNotEmpty ? p.serviceIds : p.services.map((s) => s.id));
      ownServiceIds.addAll(p.services.where((s) => !s.isAdminCreated && s.providerId != null).map((s) => s.id));
      final key = p.providerType?.key;
      if (key != null && key.isNotEmpty) {
        final res = await _api.get(url: ApiUrl.adminCreateService(key), isToken: false);
        if (res.isOk) catalogue.assignAll(J.list(res.data, ServiceModel.fromJson));
      }
    }
    isLoading.value = false;
  }

  Future<void> pickImage() async {
    final f = await FilePick.chooseSource(allowPdf: false);
    if (f.isNotEmpty) pickedImage.value = f.first;
  }

  Future<void> pickDob() async {
    final d = await Dialogs.pickDate(initial: dateOfBirth.value ?? DateTime(1990), first: DateTime(1900), last: DateTime.now());
    if (d != null) {
      dateOfBirth.value = d;
      dateOfBirthController.text = Fmt.date(d);
    }
  }

  void addContact() {
    if (contacts.length >= 5) return AppSnackBar.info("Maximum 5 emergency contacts");
    contacts.add(ContactRow());
  }

  void removeContact(ContactRow r) {
    contacts.remove(r);
    r.dispose();
  }

  void toggleService(String id) {
    selectedServiceIds.contains(id) ? selectedServiceIds.remove(id) : selectedServiceIds.add(id);
  }

  Future<void> updateProfile() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final data = <String, dynamic>{
      "fullName": nameController.text.trim(),
      "phone": numberController.text.trim(),
      "address": addressController.text.trim(),
    };
    if (isNormalUser) {
      final list = contacts.where((c) => !c.isEmpty).toList();
      if (list.any((c) => c.name.text.trim().isEmpty || c.phone.text.trim().isEmpty)) {
        return AppSnackBar.fail("Each emergency contact needs a name and a phone");
      }
      data.addAll({
        if (dateOfBirth.value != null) "dateOfBirth": Fmt.apiDate(dateOfBirth.value!),
        if (gender.value != null) "gender": gender.value,
        if (bloodGroup.value != null) "bloodGroup": bloodGroup.value,
        "identificationNumber": identificationController.text.trim(),
        "allergies": splitCsv(allergiesController.text).take(30).toList(),
        "chronicConditions": splitCsv(chronicController.text).take(30).toList(),
        "emergencyContacts": list
            .map((c) => EmergencyContact(
                  name: c.name.text.trim(),
                  phone: c.phone.text.trim(),
                  relation: c.relation.text.trim(),
                ).toJson())
            .toList(),
        if (list.isNotEmpty) "emergencyContact": list.first.phone.text.trim(),
      });
    } else {
      data.addAll({
        "displayName": displayNameController.text.trim(),
        "about": aboutController.text.trim(),
        "location": locationController.text.trim(),
        "specialization": specializationController.text.trim(),
        if (int.tryParse(experienceController.text.trim()) != null)
          "yearsOfExperience": int.parse(experienceController.text.trim()),
        "languages": splitCsv(languagesController.text),
        "serviceId": {...selectedServiceIds, ...ownServiceIds}.toList(),
      });
    }

    isSaving.value = true;
    final res = await _api.sendForm(
      url: ApiUrl.updateMyProfile,
      method: "PATCH",
      data: data,
      files: [if (pickedImage.value != null) MultipartFileData(key: "profile_image", path: pickedImage.value!.path)],
    );
    isSaving.value = false;
    if (res.isOk) {
      await SessionService.refreshMe();
      AppSnackBar.success("Profile updated");
      Get.back(result: true);
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  @override
  void onClose() {
    for (final c in [
      nameController,
      numberController,
      addressController,
      dateOfBirthController,
      genderController,
      identificationController,
      allergiesController,
      chronicController,
      displayNameController,
      aboutController,
      locationController,
      specializationController,
      experienceController,
      languagesController,
    ]) {
      c.dispose();
    }
    for (final r in contacts) {
      r.dispose();
    }
    super.onClose();
  }
}
