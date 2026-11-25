import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/app_models.dart';
import '../../../../../data/models/json.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../widget/hv_ui.dart';
import '../../../home/controller/home_controller.dart';

/// GET /insurance?forWhom=…  + delete
class InsuranceController extends GetxController {
  final _api = ApiClient();
  final items = <InsuranceModel>[].obs;
  final forWhom = 'ALL'.obs;
  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.insurances, query: {if (forWhom.value != 'ALL') "forWhom": forWhom.value});
    isLoading.value = false;
    if (res.isOk) {
      items.assignAll(Paged.parse(res.data, InsuranceModel.fromJson).items);
    } else {
      error.value = res.message;
    }
  }

  void setForWhom(String v) {
    forWhom.value = v;
    fetch();
  }

  Future<void> delete(InsuranceModel i) async {
    if (!await Dialogs.confirm(title: 'Delete insurance'.tr, message: '${'Delete'.tr} "${i.name}"?', destructive: true)) {
      return;
    }
    final res = await _api.delete(url: ApiUrl.insurance(i.id));
    if (res.isOk) {
      items.removeWhere((e) => e.id == i.id);
      AppSnackBar.success("Insurance deleted");
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().loadDashboard();
    } else {
      AppSnackBar.fail(res.message);
    }
  }
}

/// POST /insurance/create · PATCH /insurance/:id (multipart data + insurance_Photo)
class InsuranceFormController extends GetxController {
  final _api = ApiClient();
  InsuranceModel? editing;

  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final number = TextEditingController();
  final provider = TextEditingController();
  final coverage = TextEditingController();
  final familyName = TextEditingController();
  final forWhom = 'SELF'.obs;
  final startDate = Rxn<DateTime>();
  final expiryDate = Rxn<DateTime>();
  final reminderEnabled = true.obs;
  final photo = Rxn<File>();
  final existingPhoto = RxnString();
  final isSaving = false.obs;

  bool get isEdit => editing != null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['forWhom'] is String && args['forWhom'] != 'ALL') forWhom.value = args['forWhom'];
    final i = args is InsuranceModel ? args : (args is Map ? args['insurance'] : null);
    if (i is InsuranceModel) {
      editing = i;
      name.text = i.name;
      number.text = i.number;
      provider.text = i.insuranceProvider;
      coverage.text = i.coverageType ?? '';
      familyName.text = i.familyMemberName ?? '';
      forWhom.value = i.forWhom;
      startDate.value = i.startDate;
      expiryDate.value = i.expiryDate;
      reminderEnabled.value = i.reminderEnabled;
      existingPhoto.value = i.photo;
    }
  }

  Future<void> pickPhoto() async {
    final f = await FilePick.chooseSource();
    if (f.isNotEmpty) photo.value = f.first;
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (expiryDate.value == null) return AppSnackBar.fail("Select the expiry date");
    if (forWhom.value == 'FAMILY' && familyName.text.trim().isEmpty) {
      return AppSnackBar.fail("Enter the family member's name");
    }
    final data = <String, dynamic>{
      "forWhom": forWhom.value,
      if (forWhom.value == 'FAMILY') "familyMemberName": familyName.text.trim(),
      "name": name.text.trim(),
      "number": number.text.trim(),
      "insuranceProvider": provider.text.trim(),
      "expiryDate": Fmt.apiDate(expiryDate.value!),
      if (startDate.value != null) "startDate": Fmt.apiDate(startDate.value!),
      if (coverage.text.trim().isNotEmpty) "coverageType": coverage.text.trim(),
      "reminderEnabled": reminderEnabled.value,
    };
    isSaving.value = true;
    final res = await _api.sendForm(
      url: isEdit ? ApiUrl.insurance(editing!.id) : ApiUrl.postInsurance,
      method: isEdit ? "PATCH" : "POST",
      data: data,
      files: [if (photo.value != null) MultipartFileData(key: "insurance_Photo", path: photo.value!.path)],
    );
    isSaving.value = false;
    if (res.isOk) {
      AppSnackBar.success(isEdit ? "Insurance updated" : "Insurance added");
      if (Get.isRegistered<InsuranceController>()) Get.find<InsuranceController>().fetch();
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().loadDashboard();
      Get.back(result: true);
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  @override
  void onClose() {
    for (final c in [name, number, provider, coverage, familyName]) {
      c.dispose();
    }
    super.onClose();
  }
}
