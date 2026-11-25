import 'package:get/get.dart';

import '../../../../data/models/app_models.dart';
import '../../../../data/models/json.dart';
import '../../../../data/models/user_models.dart';
import '../../../../helper/tost_message/show_snackbar.dart';
import '../../../../service/api_service.dart';
import '../../../../service/api_url.dart';
import '../../../../service/socket_service.dart';

/// Patient home – GET /normal-User/home + directory/articles.
class HomeController extends GetxController {
  final _api = ApiClient();

  final isLoading = true.obs;
  final error = RxnString();

  final fullName = ''.obs;
  final profileImage = RxnString();
  final membershipId = RxnString();
  final bloodGroup = RxnString();

  final todayDoses = <DoseModel>[].obs;
  final remaining = 0.obs;
  final taken = 0.obs;
  final upcoming = <AppointmentModel>[].obs;
  final latestLog = Rxn<HealthLogModel>();
  final expiringInsurances = <InsuranceModel>[].obs;
  final activeSosId = RxnString();

  final providerTypes = <ProviderTypeModel>[].obs;
  final providers = <ProviderModel>[].obs;
  final articles = <ArticleModel>[].obs;
  final _recording = <String>{}.obs;

  String get fullImageUrl => ApiUrl.fileUrl(profileImage.value);

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    await Future.wait([loadDashboard(), _loadTypes(), _loadProviders(), _loadArticles()]);
    isLoading.value = false;
    RealtimeService.to.refreshUnreadCount();
  }

  Future<void> loadDashboard() async {
    final res = await _api.get(url: ApiUrl.patientHome);
    if (!res.isOk) {
      error.value = res.message;
      return;
    }
    error.value = null;
    final d = J.map(res.data);
    final profile = J.map(d['profile']);
    fullName.value = J.s(profile['fullName']);
    profileImage.value = J.str(profile['profile_image']);
    membershipId.value = J.str(profile['membershipId']) ?? J.str(J.map(d['healthCard'])['membershipId']);
    bloodGroup.value = J.str(profile['bloodGroup']);

    final r = J.map(d['reminders']);
    todayDoses.assignAll(J.list(r['today'], DoseModel.fromJson));
    remaining.value = J.integer(r['remaining']) ?? 0;
    taken.value = J.integer(r['taken']) ?? 0;

    upcoming.assignAll(J.list(d['upcomingAppointments'], AppointmentModel.fromJson));
    latestLog.value = d['latestHealthLog'] is Map ? HealthLogModel.fromJson(J.map(d['latestHealthLog'])) : null;
    expiringInsurances.assignAll(J.list(d['expiringInsurances'], InsuranceModel.fromJson));
    activeSosId.value = d['activeSos'] is Map ? J.str(d['activeSos']['_id']) : null;
    final unread = J.integer(d['unreadNotifications']);
    if (unread != null) RealtimeService.to.unreadCount.value = unread;
  }

  Future<void> _loadTypes() async {
    final res = await _api.get(url: ApiUrl.providerType, isToken: false);
    if (res.isOk) providerTypes.assignAll(J.list(res.data, ProviderTypeModel.fromJson).where((t) => t.isActive));
  }

  Future<void> _loadProviders() async {
    final res = await _api.get(url: ApiUrl.getAllProvider, query: {"page": 1, "limit": 5}, isToken: false);
    if (res.isOk) providers.assignAll(Paged.parse(res.data, ProviderModel.fromJson).items);
  }

  Future<void> _loadArticles() async {
    final res = await _api.get(url: ApiUrl.getAllArticle, query: {"page": 1, "limit": 10}, isToken: false);
    if (res.isOk) articles.assignAll(Paged.parse(res.data, ArticleModel.fromJson).items);
  }

  bool isRecording(DoseModel d) => _recording.contains('${d.reminderId}${d.scheduledAt}');

  /// POST /reminder/:id/intake
  Future<void> recordDose(DoseModel d, String status) async {
    final key = '${d.reminderId}${d.scheduledAt}';
    _recording.add(key);
    final res = await _api.post(
      url: ApiUrl.recordIntake(d.reminderId),
      body: {"scheduledAt": d.scheduledAt, "status": status},
    );
    _recording.remove(key);
    if (res.isOk) {
      final i = todayDoses.indexWhere((e) => e.reminderId == d.reminderId && e.scheduledAt == d.scheduledAt);
      if (i >= 0) todayDoses[i] = d.copyWith(status: status);
      if (status == 'TAKEN') taken.value++;
      if (remaining.value > 0) remaining.value--;
      AppSnackBar.success(status == 'TAKEN' ? "Marked as taken" : "Marked as skipped");
    } else {
      AppSnackBar.fail(res.message);
    }
  }
}
