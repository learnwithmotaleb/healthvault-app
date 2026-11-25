import 'package:get/get.dart';

import '../../../../../data/models/app_models.dart';
import '../../../../../data/models/json.dart';
import '../../../../../data/models/user_models.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../../service/session_service.dart';
import '../../../../../service/socket_service.dart';
import '../../../appointment/controller/appointment_controller.dart';

/// Provider dashboard.
class ProviderHomeController extends GetxController {
  final _api = ApiClient();
  final isLoading = false.obs;
  final pending = <AppointmentModel>[].obs;
  final upcoming = <AppointmentModel>[].obs;
  final pendingCount = 0.obs;
  final upcomingCount = 0.obs;
  final completedCount = 0.obs;
  final busy = <String>{}.obs;

  Rx<AccountModel?> get account => SessionService.account;
  ProfileModel? get profile => account.value?.profile;
  String get fullName => account.value?.displayName ?? '';
  String get specialization => profile?.specialization ?? _cap(profile?.providerType?.label);
  String get fullImageUrl => ApiUrl.fileUrl(profile?.profileImage);

  static String _cap(String? v) => (v == null || v.isEmpty) ? '' : v[0] + v.substring(1).toLowerCase();

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    await Future.wait([SessionService.refreshMe(), _load()]);
    isLoading.value = false;
    RealtimeService.to.refreshUnreadCount();
  }

  Future<Paged<AppointmentModel>?> _get(String status, {int limit = 5}) async {
    final res = await _api.get(url: ApiUrl.providerAppointment, query: {"status": status, "page": 1, "limit": limit});
    return res.isOk ? Paged.parse(res.data, AppointmentModel.fromJson) : null;
  }

  Future<void> _load() async {
    final results = await Future.wait([_get('PENDING', limit: 10), _get('upcoming'), _get('COMPLETED', limit: 1)]);
    if (results[0] != null) {
      pending.assignAll(results[0]!.items);
      pendingCount.value = results[0]!.total;
    }
    if (results[1] != null) {
      upcoming.assignAll(results[1]!.items.where((a) => a.status == 'CONFIRMED'));
      upcomingCount.value = results[1]!.total;
    }
    if (results[2] != null) completedCount.value = results[2]!.total;
  }

  Future<void> setStatus(AppointmentModel a, String status, {String? reason}) async {
    busy.add(a.id);
    final res = await _api.patch(url: ApiUrl.providerUpdateStatus(a.id), body: {
      "status": status,
      if (reason != null && reason.isNotEmpty) "cancellationReason": reason,
    });
    busy.remove(a.id);
    if (res.isOk) {
      AppSnackBar.success(status == 'CONFIRMED' ? "Appointment confirmed" : status == 'COMPLETED' ? "Appointment completed" : "Appointment cancelled");
      await _load();
      if (Get.isRegistered<AppointmentController>(tag: 'provider')) {
        Get.find<AppointmentController>(tag: 'provider').getMyAppointments();
      }
    } else {
      AppSnackBar.fail(res.message);
    }
  }
}
