import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/app_models.dart';
import '../../../../../data/models/json.dart';
import '../../../../../data/models/user_models.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';

/// GET /provider/all-providers with search, filters and pagination.
class ProviderSearchController extends GetxController {
  ProviderSearchController({this.initialTypeId, this.initialTypeKey});

  final String? initialTypeId;
  final String? initialTypeKey;

  final _api = ApiClient();
  final searchText = TextEditingController();
  final scroll = ScrollController();

  final providers = <ProviderModel>[].obs;
  final types = <ProviderTypeModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();
  final total = 0.obs;

  // filters
  final typeId = RxnString();
  final specialization = ''.obs;
  final location = ''.obs;
  final language = ''.obs;
  final sortBy = 'newest'.obs;

  int _page = 1;
  bool _hasMore = true;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    typeId.value = initialTypeId;
    _loadTypes();
    fetch();
    searchText.addListener(_onSearch);
    scroll.addListener(() {
      if (scroll.position.pixels > scroll.position.maxScrollExtent - 300) loadMore();
    });
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), fetch);
  }

  Future<void> _loadTypes() async {
    final res = await _api.get(url: ApiUrl.providerType, isToken: false);
    if (res.isOk) {
      types.assignAll(J.list(res.data, ProviderTypeModel.fromJson).where((t) => t.isActive));
    }
  }

  int get activeFilterCount =>
      [specialization.value, location.value, language.value].where((e) => e.isNotEmpty).length +
      (sortBy.value != 'newest' ? 1 : 0);

  Map<String, dynamic> _query(int page) => {
        "page": page,
        "limit": 15,
        "searchTerm": searchText.text.trim(),
        "providerTypeId": typeId.value,
        if (typeId.value == null && initialTypeKey != null) "providerType": initialTypeKey,
        "specialization": specialization.value,
        "location": location.value,
        "language": language.value,
        "sortBy": sortBy.value,
      };

  Future<void> fetch() async {
    _page = 1;
    _hasMore = true;
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.getAllProvider, query: _query(1), isToken: false);
    isLoading.value = false;
    if (res.isOk) {
      final paged = Paged.parse(res.data, ProviderModel.fromJson);
      providers.assignAll(paged.items);
      total.value = paged.total;
      _hasMore = paged.hasMore;
    } else {
      error.value = res.message;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoading.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    final res = await _api.get(url: ApiUrl.getAllProvider, query: _query(_page + 1), isToken: false);
    isLoadingMore.value = false;
    if (res.isOk) {
      final paged = Paged.parse(res.data, ProviderModel.fromJson);
      _page++;
      providers.addAll(paged.items);
      _hasMore = paged.hasMore;
    }
  }

  void setType(String? id) {
    typeId.value = id;
    fetch();
  }

  void applyFilters({required String spec, required String loc, required String lang, required String sort}) {
    specialization.value = spec.trim();
    location.value = loc.trim();
    language.value = lang.trim();
    sortBy.value = sort;
    fetch();
  }

  void clearFilters() => applyFilters(spec: '', loc: '', lang: '', sort: 'newest');

  @override
  void onClose() {
    _debounce?.cancel();
    searchText.dispose();
    scroll.dispose();
    super.onClose();
  }
}
