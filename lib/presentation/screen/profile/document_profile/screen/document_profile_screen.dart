import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../data/models/app_models.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/document_profile_controller.dart';

/// Medical documents vault.
class DocumentProfileScreen extends StatelessWidget {
  const DocumentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DocumentListController());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.document.tr),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        onPressed: () => Get.toNamed(RoutePath.uploadDocument, arguments: {"forWhom": c.forWhom.value}),
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: Text('Upload'.tr, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: TextField(
            controller: c.search,
            decoration: InputDecoration(
              hintText: 'Search documents'.tr,
              hintStyle: AppTextStyles.hint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
        Obx(() => ChoiceBar(
              values: ['', ...documentCategories],
              labels: ['All'.tr, ...documentCategories.map((e) => Fmt.enumLabel(e).tr)],
              selected: c.category.value,
              onSelected: c.setCategory,
            )),
        Obx(() => Row(children: [
              Expanded(
                child: ChoiceBar(
                  padding: const EdgeInsets.only(left: 12),
                  values: const ['', 'SELF', 'FAMILY'],
                  labels: ['Everyone'.tr, 'Myself'.tr, 'Family'.tr],
                  selected: c.forWhom.value,
                  onSelected: c.setForWhom,
                ),
              ),
            ])),
        Obx(() => c.tags.isEmpty
            ? const SizedBox.shrink()
            : SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: c.tags
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text("#${t.$1} (${t.$2})", style: const TextStyle(fontSize: 12)),
                              selected: c.tag.value == t.$1,
                              selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
                              onSelected: (_) => c.setTag(t.$1),
                            ),
                          ))
                      .toList(),
                ),
              )),
        Expanded(
          child: Obx(() => NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) c.loadMore();
                  return false;
                },
                child: AsyncList(
                  loading: c.isLoading.value,
                  error: c.error.value,
                  isEmpty: c.docs.isEmpty,
                  onRefresh: c.fetch,
                  empty: EmptyView(
                    icon: Icons.folder_open_outlined,
                    title: 'No documents'.tr,
                    subtitle: 'Upload prescriptions, lab results, scans and reports.'.tr,
                  ),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                    itemCount: c.docs.length,
                    itemBuilder: (_, i) => DocumentTile(doc: c.docs[i]),
                  ),
                ),
              )),
        ),
      ]),
    );
  }
}

class DocumentTile extends StatelessWidget {
  final MedicalDocumentModel doc;
  const DocumentTile({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    return HVCardBox(
      padding: const EdgeInsets.all(10),
      onTap: () => Get.toNamed(RoutePath.documentDetails, arguments: doc),
      child: Row(children: [
        doc.isPdf
            ? Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.picture_as_pdf, color: AppColors.emergencyColor, size: 30),
              )
            : ApiImage(doc.file, width: 56, height: 56, radius: BorderRadius.circular(10)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.title,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(categoryIcon(doc.category), size: 14, color: AppColors.primaryColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  [
                    Fmt.enumLabel(doc.category).tr,
                    Fmt.date(doc.documentDate ?? doc.createdAt),
                    if (doc.forWhom == 'FAMILY') doc.familyMemberName ?? 'Family'.tr,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor),
                ),
              ),
            ]),
            if (doc.tags.isNotEmpty)
              Text(doc.tags.map((t) => '#$t').join(' '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.primaryColor)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          StatusChip(doc.status),
          if (doc.isShared)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.link, size: 18, color: AppColors.primaryColor),
            ),
        ]),
      ]),
    );
  }
}
