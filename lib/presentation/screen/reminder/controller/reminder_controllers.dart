import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/app_models.dart';
import '../../../../data/models/json.dart';
import '../../../../helper/tost_message/show_snackbar.dart';
import '../../../../service/api_service.dart';
import '../../../../service/api_url.dart';
import '../../../widget/hv_ui.dart';
import '../../home/controller/home_controller.dart';

void _refreshHome() {
  if (Get.isRegistered<HomeController>()) Get.find<HomeController>().loadDashboard();
}

// =================================================================== list
class ReminderListController extends GetxController {
  final _api = ApiClient();
  final reminders = <ReminderModel>[].obs;
  final filter = 'current'.obs; // current | ended | all
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
    final res = await _api.get(url: ApiUrl.myReminder, query: {
      if (filter.value != 'all') "status": filter.value,
    });
    isLoading.value = false;
    if (res.isOk) {
      reminders.assignAll(Paged.parse(res.data, ReminderModel.fromJson).items);
    } else {
      error.value = res.message;
    }
  }

  void setFilter(String f) {
    filter.value = f;
    fetch();
  }

  Future<void> toggleActive(ReminderModel r) async {
    final res = await _api.patch(url: ApiUrl.updateReminder(r.id), body: {"isActive": !r.isActive});
    if (res.isOk) {
      AppSnackBar.success(r.isActive ? "Reminder paused" : "Reminder resumed");
      fetch();
      _refreshHome();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  Future<void> delete(ReminderModel r) async {
    final ok = await Dialogs.confirm(
      title: 'Delete reminder'.tr,
      message: 'This also deletes its dose history.'.tr,
      confirmText: 'Delete'.tr,
      destructive: true,
    );
    if (!ok) return;
    final res = await _api.delete(url: ApiUrl.deleteReminder(r.id));
    if (res.isOk) {
      reminders.removeWhere((e) => e.id == r.id);
      AppSnackBar.success("Reminder deleted");
      _refreshHome();
    } else {
      AppSnackBar.fail(res.message);
    }
  }
}

// =================================================================== form
class ReminderFormController extends GetxController {
  final _api = ApiClient();
  ReminderModel? editing;

  final formKey = GlobalKey<FormState>();
  final pillName = TextEditingController();
  final dosage = TextEditingController();
  final instructions = TextEditingController();
  final familyName = TextEditingController();

  final schedule = 'Daily'.obs;
  final times = <String>[].obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  final dayOfWeek = 1.obs; // 0 = Sunday … 6 = Saturday
  final dayOfMonth = 1.obs;
  final forFamily = false.obs;
  final isActive = true.obs;
  final prescription = Rxn<File>();
  final existingPrescription = RxnString();
  final isSaving = false.obs;

  bool get isEdit => editing != null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final r = args is ReminderModel ? args : (args is Map && args['reminder'] is ReminderModel ? args['reminder'] : null);
    if (r != null) {
      editing = r;
      pillName.text = r.pillName;
      dosage.text = r.dosage;
      instructions.text = r.instructions ?? '';
      schedule.value = ['Daily', 'Weekly', 'Monthly'].contains(r.schedule) ? r.schedule : 'Daily';
      times.assignAll(r.times);
      startDate.value = r.startDate;
      endDate.value = r.endDate;
      dayOfWeek.value = r.dayOfWeek ?? 1;
      dayOfMonth.value = r.dayOfMonth ?? 1;
      forFamily.value = r.assignedTo != 'SELF';
      familyName.text = r.assignedTo == 'SELF' ? '' : r.assignedTo;
      isActive.value = r.isActive;
      existingPrescription.value = r.prescriptionFile;
    } else {
      final now = DateTime.now();
      startDate.value = DateTime(now.year, now.month, now.day);
      endDate.value = DateTime(now.year, now.month + 1, now.day);
      times.add('08:00');
    }
  }

  Future<void> addTime() async {
    if (times.length >= 12) return AppSnackBar.info("Maximum 12 times per day");
    final t = await Dialogs.pickTime(initial: const TimeOfDay(hour: 8, minute: 0));
    if (t == null) return;
    final s = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    if (!times.contains(s)) {
      times.add(s);
      times.sort();
    }
  }

  Future<void> pickPrescription() async {
    final f = await FilePick.chooseSource();
    if (f.isNotEmpty) prescription.value = f.first;
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (times.isEmpty) return AppSnackBar.fail("Add at least one time");
    if (startDate.value == null || endDate.value == null) return AppSnackBar.fail("Select start and end dates");
    if (endDate.value!.isBefore(startDate.value!)) return AppSnackBar.fail("End date must be after the start date");
    if (forFamily.value && familyName.text.trim().isEmpty) return AppSnackBar.fail("Enter the family member's name");

    final data = <String, dynamic>{
      "pillName": pillName.text.trim(),
      "dosage": dosage.text.trim(),
      "schedule": schedule.value,
      "times": times.toList(),
      "startDate": Fmt.apiDate(startDate.value!),
      "endDate": Fmt.apiDate(endDate.value!),
      "instructions": instructions.text.trim(),
      "assignedTo": forFamily.value ? familyName.text.trim() : "SELF",
      "isActive": isActive.value,
      if (schedule.value == 'Weekly') "scheduleMeta": {"dayOfWeek": dayOfWeek.value},
      if (schedule.value == 'Monthly') "scheduleMeta": {"dayOfMonth": dayOfMonth.value},
    };

    isSaving.value = true;
    final res = await _api.sendForm(
      url: isEdit ? ApiUrl.updateReminder(editing!.id) : ApiUrl.createReminder,
      method: isEdit ? "PATCH" : "POST",
      data: data,
      files: [if (prescription.value != null) MultipartFileData(key: "prescription_file", path: prescription.value!.path)],
    );
    isSaving.value = false;

    if (res.isOk) {
      AppSnackBar.success(isEdit ? "Reminder updated" : "Reminder created");
      if (Get.isRegistered<ReminderListController>()) Get.find<ReminderListController>().fetch();
      _refreshHome();
      Get.back(result: true);
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  @override
  void onClose() {
    pillName.dispose();
    dosage.dispose();
    instructions.dispose();
    familyName.dispose();
    super.onClose();
  }
}

// =================================================================== today
class TodayDosesController extends GetxController {
  final _api = ApiClient();
  final doses = <DoseModel>[].obs;
  final isLoading = false.obs;
  final error = RxnString();
  final busy = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.todayDoses);
    isLoading.value = false;
    if (res.isOk) {
      doses.assignAll(J.list(res.data is List ? res.data : J.map(res.data)['data'], DoseModel.fromJson));
    } else {
      error.value = res.message;
    }
  }

  Future<void> record(DoseModel d, String status, {String? note}) async {
    final key = d.reminderId + d.scheduledAt;
    busy.add(key);
    final res = await _api.post(url: ApiUrl.recordIntake(d.reminderId), body: {
      "scheduledAt": d.scheduledAt,
      "status": status,
      if (note != null && note.isNotEmpty) "note": note,
    });
    busy.remove(key);
    if (res.isOk) {
      final i = doses.indexWhere((e) => e.reminderId == d.reminderId && e.scheduledAt == d.scheduledAt);
      if (i >= 0) doses[i] = d.copyWith(status: status);
      _refreshHome();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  /// Opened from a push (`reminderId` + `scheduledAt`).
  static Future<void> quickRecord(String reminderId, String scheduledAt, String status) async {
    final res = await ApiClient().post(
      url: ApiUrl.recordIntake(reminderId),
      body: {"scheduledAt": scheduledAt, "status": status},
    );
    res.isOk ? AppSnackBar.success("Saved") : AppSnackBar.fail(res.message);
    _refreshHome();
  }
}

// =================================================================== adherence
class AdherenceController extends GetxController {
  final _api = ApiClient();
  final summary = Rxn<AdherenceStats>();
  final byReminder = <AdherenceStats>[].obs;
  final history = <IntakeRecord>[].obs;
  final from = Rx<DateTime>(DateTime.now().subtract(const Duration(days: 30)));
  final to = Rx<DateTime>(DateTime.now());
  final reminderId = RxnString();
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();
  int _page = 1;
  bool _hasMore = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['reminderId'] != null) reminderId.value = args['reminderId'].toString();
    fetch();
  }

  Map<String, dynamic> _q(int page) => {
        "from": Fmt.apiDate(from.value),
        "to": Fmt.apiDate(to.value),
        "reminderId": reminderId.value,
        "page": page,
        "limit": 20,
      };

  Future<void> fetch() async {
    _page = 1;
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.adherence, query: _q(1));
    isLoading.value = false;
    if (res.isOk) {
      final d = J.map(res.data);
      summary.value = AdherenceStats.fromJson(J.map(d['summary']));
      byReminder.assignAll(J.list(d['byReminder'], AdherenceStats.fromJson));
      final h = Paged.parse(d['history'], IntakeRecord.fromJson);
      history.assignAll(h.items);
      _hasMore = h.hasMore;
    } else {
      error.value = res.message;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value) return;
    isLoadingMore.value = true;
    final res = await _api.get(url: ApiUrl.adherence, query: _q(_page + 1));
    isLoadingMore.value = false;
    if (res.isOk) {
      final h = Paged.parse(J.map(res.data)['history'], IntakeRecord.fromJson);
      _page++;
      history.addAll(h.items);
      _hasMore = h.hasMore;
    }
  }

  void setRange(int days) {
    to.value = DateTime.now();
    from.value = DateTime.now().subtract(Duration(days: days));
    fetch();
  }
}
