import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/app_models.dart';
import '../../../../../data/models/json.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../widget/hv_ui.dart';
import '../../../home/controller/home_controller.dart';

/// GET /healthLog (paginated, newest first) + delete.
class HealthLogController extends GetxController {
  final _api = ApiClient();
  final logs = <HealthLogModel>[].obs;
  final forWhom = 'SELF'.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();
  int _page = 1;
  bool _hasMore = false;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    _page = 1;
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.healthLogs, query: {"forWhom": forWhom.value, "page": 1, "limit": 30});
    isLoading.value = false;
    if (res.isOk) {
      final p = Paged.parse(res.data, HealthLogModel.fromJson);
      logs.assignAll(p.items);
      _hasMore = p.hasMore;
    } else {
      error.value = res.message;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value) return;
    isLoadingMore.value = true;
    final res = await _api.get(url: ApiUrl.healthLogs, query: {"forWhom": forWhom.value, "page": _page + 1, "limit": 30});
    isLoadingMore.value = false;
    if (res.isOk) {
      final p = Paged.parse(res.data, HealthLogModel.fromJson);
      _page++;
      logs.addAll(p.items);
      _hasMore = p.hasMore;
    }
  }

  void setForWhom(String v) {
    forWhom.value = v;
    fetch();
  }

  Future<void> delete(HealthLogModel l) async {
    if (!await Dialogs.confirm(title: 'Delete entry'.tr, message: 'Delete this health log?'.tr, destructive: true)) return;
    final res = await _api.delete(url: ApiUrl.healthLog(l.id));
    if (res.isOk) {
      logs.removeWhere((e) => e.id == l.id);
      AppSnackBar.success("Deleted");
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().loadDashboard();
    } else {
      AppSnackBar.fail(res.message);
    }
  }
}

/// POST /healthLog/create or PATCH /healthLog/:id
class HealthLogFormController extends GetxController {
  final _api = ApiClient();
  HealthLogModel? editing;

  final formKey = GlobalKey<FormState>();
  final systolic = TextEditingController();
  final diastolic = TextEditingController();
  final heartRate = TextEditingController();
  final weight = TextEditingController();
  final bloodSugar = TextEditingController();
  final temperature = TextEditingController();
  final oxygen = TextEditingController();
  final note = TextEditingController();
  final familyName = TextEditingController();
  final forWhom = 'SELF'.obs;
  final recordedAt = Rx<DateTime>(DateTime.now());
  final isSaving = false.obs;

  bool get isEdit => editing != null;

  String _n(num? v) => v == null ? '' : HealthLogModel.fmt(v);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['forWhom'] != null) forWhom.value = args['forWhom'];
    final l = args is HealthLogModel ? args : (args is Map ? args['log'] : null);
    if (l is HealthLogModel) {
      editing = l;
      forWhom.value = l.forWhom;
      familyName.text = l.familyMemberName ?? '';
      systolic.text = _n(l.systolic);
      diastolic.text = _n(l.diastolic);
      heartRate.text = _n(l.heartRate);
      weight.text = _n(l.weight);
      bloodSugar.text = _n(l.bloodSugar);
      temperature.text = _n(l.temperature);
      oxygen.text = _n(l.oxygenSaturation);
      note.text = l.note ?? '';
      if (l.recordedAt != null) recordedAt.value = l.recordedAt!;
    }
  }

  num? _v(TextEditingController c) => num.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final values = {
      "systolic": _v(systolic),
      "diastolic": _v(diastolic),
      "heartRate": _v(heartRate),
      "weight": _v(weight),
      "bloodSugar": _v(bloodSugar),
      "temperature": _v(temperature),
      "oxygenSaturation": _v(oxygen),
    };
    if (values.values.every((v) => v == null)) return AppSnackBar.fail("Enter at least one measurement");
    if ((values['systolic'] == null) != (values['diastolic'] == null)) {
      return AppSnackBar.fail("Enter both systolic and diastolic blood pressure");
    }
    if (forWhom.value == 'FAMILY' && familyName.text.trim().isEmpty) {
      return AppSnackBar.fail("Enter the family member's name");
    }
    if (recordedAt.value.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return AppSnackBar.fail("The date can't be in the future");
    }

    final body = <String, dynamic>{
      "forWhom": forWhom.value,
      if (forWhom.value == 'FAMILY') "familyMemberName": familyName.text.trim(),
      "recordedAt": recordedAt.value.toUtc().toIso8601String(),
      ...Map.fromEntries(values.entries.where((e) => e.value != null)),
      if (note.text.trim().isNotEmpty) "note": note.text.trim(),
    };

    isSaving.value = true;
    final res = isEdit
        ? await _api.patch(url: ApiUrl.healthLog(editing!.id), body: body)
        : await _api.post(url: ApiUrl.postHealthLog, body: body);
    isSaving.value = false;

    if (res.isOk) {
      AppSnackBar.success(isEdit ? "Health log updated" : "Health log saved");
      if (Get.isRegistered<HealthLogController>()) Get.find<HealthLogController>().fetch();
      if (Get.isRegistered<HomeController>()) Get.find<HomeController>().loadDashboard();
      Get.back(result: true);
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  @override
  void onClose() {
    for (final c in [systolic, diastolic, heartRate, weight, bloodSugar, temperature, oxygen, note, familyName]) {
      c.dispose();
    }
    super.onClose();
  }
}

/// GET /healthLog/trends
class HealthTrendsController extends GetxController {
  final _api = ApiClient();
  final points = <TrendPoint>[].obs;
  final forWhom = 'SELF'.obs;
  final groupBy = 'day'.obs;
  final metric = 'bloodPressure'.obs; // bloodPressure = systolic + diastolic
  final days = 30.obs;
  final isLoading = false.obs;
  final error = RxnString();

  static const metrics = {
    'bloodPressure': ('Blood pressure', 'mmHg'),
    'heartRate': ('Heart rate', 'bpm'),
    'weight': ('Weight', 'kg'),
    'bloodSugar': ('Blood sugar', 'mg/dL'),
    'temperature': ('Temperature', '°C'),
    'oxygenSaturation': ('Oxygen', '%'),
  };

  List<String> get apiMetrics => metric.value == 'bloodPressure' ? ['systolic', 'diastolic'] : [metric.value];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['forWhom'] is String) forWhom.value = args['forWhom'];
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    error.value = null;
    final now = DateTime.now();
    final res = await _api.get(url: ApiUrl.healthLogTrends, query: {
      "forWhom": forWhom.value,
      "metrics": apiMetrics.join(','),
      "groupBy": groupBy.value,
      "from": Fmt.apiDate(now.subtract(Duration(days: days.value))),
      "to": Fmt.apiDate(now.add(const Duration(days: 1))),
    });
    isLoading.value = false;
    if (res.isOk) {
      points.assignAll(J.list(J.map(res.data)['points'], TrendPoint.fromJson));
    } else {
      error.value = res.message;
    }
  }

  void setMetric(String m) {
    metric.value = m;
    fetch();
  }

  void setRange(int d) {
    days.value = d;
    groupBy.value = d <= 31 ? 'day' : (d <= 120 ? 'week' : 'month');
    fetch();
  }
}
