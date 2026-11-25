import 'package:get/get.dart';

import '../../../../../data/models/json.dart';
import '../../../../../data/models/user_models.dart';
import '../../../../../helper/athens_time.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../widget/hv_ui.dart';

/// Weekly availability – days + slots (Greek time).
class ProviderEditScheduleController extends GetxController {
  final _api = ApiClient();
  final days = <AvailabilityDay>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  AvailabilityDay? dayFor(String key) => days.firstWhereOrNull((d) => d.dayOfWeek == key);

  Future<void> fetch() async {
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.myAvailabilityDays);
    isLoading.value = false;
    if (res.isOk) {
      days.assignAll(J.list(res.data is List ? res.data : J.map(res.data)['data'], AvailabilityDay.fromJson));
    } else {
      error.value = res.message;
    }
  }

  /// Ensures the day exists, then adds a slot.
  Future<void> addSlot(String dayKey, String start, String end) async {
    if (AthensTime.minutesOf(end) <= AthensTime.minutesOf(start)) {
      return AppSnackBar.fail("End time must be after start time");
    }
    isSaving.value = true;
    var day = dayFor(dayKey);
    if (day == null) {
      final r = await _api.post(url: ApiUrl.createAvailabilityDay, body: {"dayOfWeek": dayKey});
      if (r.isOk && r.data is Map) {
        day = AvailabilityDay.fromJson(J.map(r.data));
      } else if (r.statusCode == 409) {
        await fetch();
        day = dayFor(dayKey);
      } else {
        isSaving.value = false;
        return AppSnackBar.fail(r.message);
      }
    }
    if (day == null) {
      isSaving.value = false;
      return AppSnackBar.fail("Could not create the day");
    }
    final res = await _api.post(url: ApiUrl.createAvailabilitySlot, body: {
      "availabilityDayId": day.id,
      "startTime": start,
      "endTime": end,
    });
    isSaving.value = false;
    if (res.isOk) {
      AppSnackBar.success("Time slot added");
    } else {
      AppSnackBar.fail(res.message);
    }
    fetch();
  }

  Future<void> deleteSlot(AvailabilitySlot s) async {
    final res = await _api.delete(url: ApiUrl.deleteAvailabilitySlot(s.id));
    res.isOk ? AppSnackBar.success("Time slot removed") : AppSnackBar.fail(res.message);
    fetch();
  }

  Future<void> deleteDay(AvailabilityDay d) async {
    if (!await Dialogs.confirm(
      title: 'Remove day'.tr,
      message: "${d.dayOfWeek.tr}: ${'Remove this day and all its time slots?'.tr}",
      destructive: true,
    )) {
      return;
    }
    final res = await _api.delete(url: ApiUrl.deleteAvailabilityDay(d.id));
    res.isOk ? AppSnackBar.success("Day removed") : AppSnackBar.fail(res.message);
    fetch();
  }
}
