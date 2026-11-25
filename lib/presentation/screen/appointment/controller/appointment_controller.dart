import 'dart:io';

import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/models/app_models.dart';
import '../../../../data/models/json.dart';
import '../../../../helper/tost_message/show_snackbar.dart';
import '../../../../service/api_service.dart';
import '../../../../service/api_url.dart';

/// Paginated appointment list. Used by patients (my-appointments) and
/// providers (provider-appointments) – see [forProvider].
class AppointmentController extends GetxController {
  AppointmentController({this.forProvider = false});

  final bool forProvider;
  final _api = ApiClient();

  final appointments = <AppointmentModel>[].obs;
  final status = 'upcoming'.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();
  final total = 0.obs;
  int _page = 1;
  bool _hasMore = true;

  String get _url => forProvider ? ApiUrl.providerAppointment : ApiUrl.myAppointment;

  @override
  void onInit() {
    super.onInit();
    getMyAppointments();
  }

  Future<void> getMyAppointments() async {
    _page = 1;
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: _url, query: {
      "page": 1,
      "limit": 15,
      if (status.value != 'all') "status": status.value,
    });
    isLoading.value = false;
    if (res.isOk) {
      final paged = Paged.parse(res.data, AppointmentModel.fromJson);
      appointments.assignAll(paged.items);
      total.value = paged.total;
      _hasMore = paged.hasMore;
    } else {
      error.value = res.message;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoading.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    final res = await _api.get(url: _url, query: {
      "page": _page + 1,
      "limit": 15,
      if (status.value != 'all') "status": status.value,
    });
    isLoadingMore.value = false;
    if (res.isOk) {
      final paged = Paged.parse(res.data, AppointmentModel.fromJson);
      _page++;
      appointments.addAll(paged.items);
      _hasMore = paged.hasMore;
    }
  }

  void setStatus(String s) {
    if (status.value == s) return;
    status.value = s;
    getMyAppointments();
  }

  Future<void> refreshAppointments() => getMyAppointments();
}

/// One appointment (patient or provider view).
class AppointmentDetailsController extends GetxController {
  AppointmentDetailsController({this.forProvider = false});

  final bool forProvider;
  final _api = ApiClient();
  final appointment = Rxn<AppointmentModel>();
  final isLoading = false.obs;
  final isWorking = false.obs;
  final error = RxnString();
  late String id;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    id = args is Map ? (args['id'] ?? args['appointmentId'] ?? '').toString() : args?.toString() ?? '';
    load();
  }

  Future<void> load() async {
    if (id.isEmpty) return;
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(
      url: forProvider ? ApiUrl.providerAppointmentDetails(id) : ApiUrl.myAppointmentDetails(id),
    );
    isLoading.value = false;
    if (res.isOk && res.data is Map) {
      appointment.value = AppointmentModel.fromJson(J.map(res.data));
    } else {
      error.value = res.message;
    }
  }

  void _refreshLists() {
    for (final tag in [null, 'provider']) {
      if (Get.isRegistered<AppointmentController>(tag: tag)) {
        Get.find<AppointmentController>(tag: tag).getMyAppointments();
      }
    }
  }

  /// PATCH /appointment/cancel/:id (patient)
  Future<void> cancel(String reason) async {
    isWorking.value = true;
    final res = await _api.patch(url: ApiUrl.cancelAppointment(id), body: {
      if (reason.isNotEmpty) "cancellationReason": reason,
    });
    isWorking.value = false;
    if (res.isOk) {
      AppSnackBar.success("Appointment cancelled");
      await load();
      _refreshLists();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  /// PATCH /appointment/provider-update-status/:id (provider)
  Future<void> updateStatus(String status, {String? reason}) async {
    isWorking.value = true;
    final res = await _api.patch(url: ApiUrl.providerUpdateStatus(id), body: {
      "status": status,
      if (reason != null && reason.isNotEmpty) "cancellationReason": reason,
    });
    isWorking.value = false;
    if (res.isOk) {
      AppSnackBar.success(status == 'CONFIRMED' ? "Appointment confirmed" : status == 'COMPLETED' ? "Appointment completed" : "Appointment cancelled");
      await load();
      _refreshLists();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  /// GET …/calendar.ics → open with the calendar app (or share).
  Future<void> addToCalendar() async {
    isWorking.value = true;
    final res = await _api.download(ApiUrl.appointmentCalendar(id));
    isWorking.value = false;
    if (res == null || res.statusCode != 200) {
      AppSnackBar.fail("Could not download the calendar file");
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/appointment-$id.ics');
    await file.writeAsBytes(res.bodyBytes);
    final opened = await OpenFilex.open(file.path, type: 'text/calendar');
    if (opened.type != ResultType.done) {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'text/calendar')]));
    }
  }
}
