import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../data/models/app_models.dart';
import '../../../../../data/models/json.dart';
import '../../../../../data/models/user_models.dart';
import '../../../../../helper/athens_time.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';

/// Provider details (GET /provider/:id) + booking (POST /appointment/create-appointment).
class InfoProviderDetailsController extends GetxController {
  final _api = ApiClient();

  final provider = Rxn<ProviderModel>();
  final availability = <AvailabilityDay>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // booking state
  final reasonController = TextEditingController();
  final selectedService = Rxn<ServiceModel>();
  final selectedDate = Rxn<DateTime>(); // Athens calendar date (fields only)
  final selectedSlot = RxnString(); // "HH:mm" Greek time
  final isBooking = false.obs;

  late String profileId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    profileId = args is Map ? (args['profileId'] ?? args['providerId'] ?? '').toString() : '';
    if (profileId.isNotEmpty) getProviderDetails(profileId);
  }

  Future<void> getProviderDetails(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    final res = await _api.get(url: ApiUrl.getSingleProviderById(id), isToken: false);
    if (res.isOk && res.data is Map) {
      final p = ProviderModel.fromJson(J.map(res.data));
      provider.value = p;
      availability.assignAll(p.availabilityDays);
      if (p.services.length == 1) selectedService.value = p.services.first;
      // availability-day endpoint is the source of truth for booking
      final av = await _api.get(url: ApiUrl.getProviderAvailability(id), isToken: false);
      if (av.isOk) availability.assignAll(J.list(av.data, AvailabilityDay.fromJson));
    } else {
      errorMessage.value = res.message;
    }
    isLoading.value = false;
  }

  bool get acceptsAnyTime => availability.every((d) => d.slots.isEmpty);

  /// Weekdays (MON…) the provider works.
  Set<String> get workingDays => availability.where((d) => d.slots.isNotEmpty).map((d) => d.dayOfWeek).toSet();

  bool isDateSelectable(DateTime d) {
    if (acceptsAnyTime) return true;
    return workingDays.contains(AvailabilityDay.keyForWeekday(d.weekday));
  }

  /// 30-minute slots for the selected date, in Greek time, excluding the past.
  List<String> slotsFor(DateTime date) {
    final key = AvailabilityDay.keyForWeekday(date.weekday);
    final day = availability.firstWhereOrNull((d) => d.dayOfWeek == key);
    if (day == null) return [];
    final out = <String>[];
    final minUtc = DateTime.now().toUtc().add(const Duration(minutes: 5));
    for (final s in day.slots) {
      final start = AthensTime.minutesOf(s.startTime);
      final end = AthensTime.minutesOf(s.endTime);
      for (var m = start; m + 30 <= end; m += 30) {
        final utc = AthensTime.toUtc(date.year, date.month, date.day, m ~/ 60, m % 60);
        if (utc.isAfter(minUtc)) out.add(AthensTime.hhmm(m));
      }
    }
    out.sort();
    return out.toSet().toList();
  }

  void pickDate(DateTime d) {
    selectedDate.value = DateTime(d.year, d.month, d.day);
    selectedSlot.value = null;
  }

  Future<void> book() async {
    final p = provider.value;
    if (p == null) return;
    if (selectedService.value == null) return AppSnackBar.fail("Please select a service");
    if (selectedDate.value == null) return AppSnackBar.fail("Please select a date");
    if (selectedSlot.value == null) return AppSnackBar.fail("Please select a time");
    if (reasonController.text.trim().isEmpty) return AppSnackBar.fail("Please write the reason for your visit");

    final d = selectedDate.value!;
    final m = AthensTime.minutesOf(selectedSlot.value!);
    final utc = AthensTime.toUtc(d.year, d.month, d.day, m ~/ 60, m % 60);
    if (utc.isBefore(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
      return AppSnackBar.fail("Please choose a time at least 5 minutes from now");
    }

    isBooking.value = true;
    final res = await _api.post(url: ApiUrl.createAppointment, body: {
      "providerId": p.id,
      "serviceId": selectedService.value!.id,
      "reasonForVisit": reasonController.text.trim(),
      "appointmentDateTime": utc.toIso8601String(),
    });
    isBooking.value = false;

    if (res.isOk) {
      AppSnackBar.success("Appointment requested. The provider will confirm it soon.");
      final a = res.data is Map ? AppointmentModel.fromJson(J.map(res.data)) : null;
      Get.back(); // close booking screen
      if (a != null) Get.toNamed(RoutePath.appointmentDetails, arguments: {"id": a.id});
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}
