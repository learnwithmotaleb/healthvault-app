import 'package:get/get.dart';

import '../../../../../data/models/json.dart';
import '../../../../../data/models/user_models.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../../service/session_service.dart';
import '../../../../widget/hv_ui.dart';

/// Provider services: own services (CRUD) + catalogue services on the profile.
class ProviderServiceController extends GetxController {
  final _api = ApiClient();
  final mine = <ServiceModel>[].obs;
  final catalogue = <ServiceModel>[].obs;
  final profileServiceIds = <String>{}.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    error.value = null;
    final acc = await SessionService.refreshMe();
    final p = acc?.profile;
    profileServiceIds
      ..clear()
      ..addAll(p?.serviceIds.isNotEmpty == true ? p!.serviceIds : (p?.services.map((s) => s.id) ?? const <String>[]));

    final res = await _api.get(url: ApiUrl.myCreateService);
    if (res.isOk) {
      mine.assignAll(Paged.parse(res.data, ServiceModel.fromJson).items);
    } else {
      error.value = res.message;
    }
    final key = p?.providerType?.key;
    if (key != null && key.isNotEmpty) {
      final cat = await _api.get(url: ApiUrl.adminCreateService(key), isToken: false);
      if (cat.isOk) catalogue.assignAll(J.list(cat.data, ServiceModel.fromJson));
    }
    isLoading.value = false;
  }

  Future<bool> create(String title, num price) async {
    isSaving.value = true;
    final res = await _api.post(url: ApiUrl.createService, body: {"title": title, "price": price});
    isSaving.value = false;
    if (res.isOk) {
      AppSnackBar.success("Service added");
      fetch();
      return true;
    }
    AppSnackBar.fail(res.message);
    return false;
  }

  Future<bool> updateService(ServiceModel s, String title, num price) async {
    isSaving.value = true;
    final res = await _api.patch(url: ApiUrl.serviceUpdate(s.id), body: {"title": title, "price": price});
    isSaving.value = false;
    if (res.isOk) {
      AppSnackBar.success("Service updated");
      fetch();
      return true;
    }
    AppSnackBar.fail(res.message);
    return false;
  }

  Future<void> delete(ServiceModel s) async {
    if (!await Dialogs.confirm(title: 'Delete service'.tr, message: '${'Delete'.tr} "${s.title}"?', destructive: true)) return;
    final res = await _api.delete(url: ApiUrl.serviceDelete(s.id));
    if (res.isOk) {
      mine.removeWhere((e) => e.id == s.id);
      AppSnackBar.success("Service deleted");
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  /// Add/remove a catalogue service on the profile (PATCH /user/updateMe { serviceId }).
  Future<void> toggleCatalogue(ServiceModel s) async {
    final next = {...profileServiceIds};
    next.contains(s.id) ? next.remove(s.id) : next.add(s.id);
    isSaving.value = true;
    final res = await _api.patch(url: ApiUrl.updateMyProfile, body: {"serviceId": next.toList()});
    isSaving.value = false;
    if (res.isOk) {
      profileServiceIds
        ..clear()
        ..addAll(next);
      SessionService.refreshMe();
    } else {
      AppSnackBar.fail(res.message);
    }
  }
}
