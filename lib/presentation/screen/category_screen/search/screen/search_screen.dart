import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../../../../widget/provider_tile.dart';
import '../controller/provider_search_controller.dart';

/// Provider directory. Pass `providerTypeId` / `providerTypeLabel` in arguments
/// to open a category (e.g. Doctors); otherwise it's the global search.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ProviderSearchController c;
  late final String tag;
  String? title;
  bool isCategory = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments is Map ? Get.arguments as Map : {};
    final typeId = args['providerTypeId']?.toString();
    final typeKey = args['providerTypeKey']?.toString();
    title = args['providerTypeLabel']?.toString();
    isCategory = typeId != null && typeId.isNotEmpty;
    tag = 'search-${typeId ?? 'all'}-${DateTime.now().microsecondsSinceEpoch}';
    c = Get.put(ProviderSearchController(initialTypeId: typeId, initialTypeKey: typeKey), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<ProviderSearchController>(tag: tag);
    super.dispose();
  }

  void _openFilters() {
    final spec = TextEditingController(text: c.specialization.value);
    final loc = TextEditingController(text: c.location.value);
    final lang = TextEditingController(text: c.language.value);
    final sort = c.sortBy.value.obs;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text('Filters'.tr, style: AppTextStyles.title)),
                TextButton(
                  onPressed: () {
                    Get.back();
                    c.clearFilters();
                  },
                  child: Text('Clear'.tr),
                ),
              ]),
              const SizedBox(height: 8),
              LabeledField(label: 'Specialization'.tr, controller: spec, hint: 'cardio'),
              LabeledField(label: 'City / area'.tr, controller: loc, hint: 'Athens'),
              LabeledField(label: 'Language'.tr, controller: lang, hint: 'English'),
              Text('Sort by'.tr, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500)),
              Obx(() => ChoiceBar(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    values: const ['newest', 'name', 'experience'],
                    labels: ['Newest'.tr, 'Name'.tr, 'Experience'.tr],
                    selected: sort.value,
                    onSelected: (v) => sort.value = v,
                  )),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Apply'.tr,
                onPressed: () {
                  Get.back();
                  c.applyFilters(spec: spec.text, loc: loc.text, lang: lang.text, sort: sort.value);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: title ?? 'Search'.tr),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: c.searchText,
                  autofocus: !isCategory,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchByProvider.tr,
                    hintStyle: AppTextStyles.hint,
                    prefixIcon: const Icon(Icons.search, color: AppColors.hintColor),
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: c.searchText,
                      builder: (_, v, __) => v.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(icon: const Icon(Icons.close), onPressed: c.searchText.clear),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => Badge(
                    isLabelVisible: c.activeFilterCount > 0,
                    label: Text('${c.activeFilterCount}'),
                    child: IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.primaryColor),
                      onPressed: _openFilters,
                      icon: const Icon(Icons.tune, color: Colors.white),
                    ),
                  )),
            ]),
          ),
          if (!isCategory)
            Obx(() => c.types.isEmpty
                ? const SizedBox(height: 8)
                : ChoiceBar(
                    values: ['', ...c.types.map((t) => t.id)],
                    labels: ['All'.tr, ...c.types.map((t) => Fmt.enumLabel(t.label))],
                    selected: c.typeId.value ?? '',
                    onSelected: (v) => c.setType(v.isEmpty ? null : v),
                  )),
          Expanded(
            child: Obx(() => AsyncList(
                  loading: c.isLoading.value,
                  error: c.error.value,
                  isEmpty: c.providers.isEmpty,
                  onRefresh: c.fetch,
                  empty: EmptyView(
                    icon: Icons.search_off,
                    title: 'No providers found'.tr,
                    subtitle: 'Try another name, city or filter.'.tr,
                  ),
                  child: ListView.builder(
                    controller: c.scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: c.providers.length + 1,
                    itemBuilder: (_, i) {
                      if (i == c.providers.length) {
                        return Obx(() => c.isLoadingMore.value
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                              )
                            : const SizedBox(height: 8));
                      }
                      return ProviderTile(provider: c.providers[i]);
                    },
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
