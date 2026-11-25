import 'package:get/get.dart';

import '../../../../../data/models/app_models.dart';
import '../../../../../data/models/json.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';

/// Global favorites store – GET/POST/DELETE /favorite.
class FavouriteController extends GetxController {
  static FavouriteController get to => Get.isRegistered<FavouriteController>()
      ? Get.find<FavouriteController>()
      : Get.put(FavouriteController(), permanent: true);

  final _api = ApiClient();
  final favorites = <FavoriteModel>[].obs;
  final ids = <String>{}.obs;
  final isLoading = false.obs;
  final error = RxnString();
  final _busy = <String>{};

  @override
  void onInit() {
    super.onInit();
    fetchFavorites();
  }

  bool isFavorite(String providerId) => ids.contains(providerId);

  Future<void> fetchFavorites() async {
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.getAllFavorite);
    isLoading.value = false;
    if (res.isOk) {
      final list = Paged.parse(res.data, FavoriteModel.fromJson).items;
      favorites.assignAll(list);
      ids
        ..clear()
        ..addAll(list.map((e) => e.providerId.isNotEmpty ? e.providerId : (e.provider?.id ?? '')));
    } else {
      error.value = res.message;
    }
  }

  Future<void> toggleFavorite(String providerId, {String? providerName}) async {
    if (providerId.isEmpty || _busy.contains(providerId)) return;
    _busy.add(providerId);
    final wasFav = isFavorite(providerId);
    // optimistic update
    wasFav ? ids.remove(providerId) : ids.add(providerId);
    ids.refresh();

    final res = wasFav
        ? await _api.delete(url: ApiUrl.removeFavorite(providerId))
        : await _api.post(url: ApiUrl.createFavorite(providerId));
    _busy.remove(providerId);

    if (res.isOk || (!wasFav && res.statusCode == 409)) {
      if (wasFav) {
        favorites.removeWhere((f) => f.providerId == providerId);
        AppSnackBar.success("${providerName ?? 'Provider'.tr} ${'removed from favorites'.tr}");
      } else {
        AppSnackBar.success("${providerName ?? 'Provider'.tr} ${'added to favorites'.tr}");
        fetchFavorites();
      }
    } else {
      wasFav ? ids.add(providerId) : ids.remove(providerId);
      ids.refresh();
      AppSnackBar.fail(res.message);
    }
  }
}
