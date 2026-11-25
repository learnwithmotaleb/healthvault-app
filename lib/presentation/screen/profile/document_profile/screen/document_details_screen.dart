import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/app_models.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/file_viewer.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/document_profile_controller.dart';

class DocumentDetailsScreen extends StatefulWidget {
  const DocumentDetailsScreen({super.key});

  @override
  State<DocumentDetailsScreen> createState() => _DocumentDetailsScreenState();
}

class _DocumentDetailsScreenState extends State<DocumentDetailsScreen> {
  final tag = 'doc-${DateTime.now().microsecondsSinceEpoch}';
  late final DocumentDetailsController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(DocumentDetailsController(), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<DocumentDetailsController>(tag: tag);
    super.dispose();
  }

  Future<void> _share() async {
    final hours = await Get.bottomSheet<int>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Share with a doctor'.tr, style: AppTextStyles.title.copyWith(fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Anyone with the link can open the file until it expires.'.tr,
                  textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.hintColor)),
            ),
            for (final h in [(1, '1 hour'), (24, '24 hours'), (72, '3 days'), (168, '7 days'), (720, '30 days')])
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: AppColors.primaryColor),
                title: Text(h.$2.tr),
                onTap: () => Get.back(result: h.$1),
              ),
          ]),
        ),
      ),
    );
    if (hours != null) c.createShare(hours);
  }

  Future<void> _edit(MedicalDocumentModel d) async {
    final title = TextEditingController(text: d.title);
    final tags = TextEditingController(text: d.tags.join(', '));
    final category = d.category.obs;
    final ok = await Get.bottomSheet<bool>(
      Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Edit document'.tr, style: AppTextStyles.title.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            LabeledField(label: 'Title'.tr, controller: title),
            Obx(() => ChoiceBar(
                  padding: const EdgeInsets.only(bottom: 8),
                  values: documentCategories,
                  labels: documentCategories.map((e) => Fmt.enumLabel(e).tr).toList(),
                  selected: category.value,
                  onSelected: (v) => category.value = v,
                )),
            LabeledField(label: 'Tags (comma separated)'.tr, controller: tags),
            PrimaryButton(label: 'Save'.tr, onPressed: () => Get.back(result: true)),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
    if (ok == true) {
      c.updateMeta({
        "title": title.text.trim(),
        "category": category.value,
        "tags": splitCsv(tags.text).map((e) => e.toLowerCase()).toSet().take(15).toList(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'Document'.tr, actions: [
        Obx(() => c.doc.value == null
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: () => _edit(c.doc.value!),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryColor),
              )),
      ]),
      body: Obx(() {
        final d = c.doc.value;
        if (d == null) {
          return c.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : EmptyView(title: 'Document not found'.tr);
        }
        return ListView(padding: const EdgeInsets.all(16), children: [
          GestureDetector(
            onTap: () => FileViewer.open(d.file, title: d.title, mimeType: d.fileType),
            child: d.isPdf
                ? Container(
                    height: 180,
                    decoration: BoxDecoration(color: const Color(0xFFFDECEA), borderRadius: BorderRadius.circular(14)),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.picture_as_pdf, size: 64, color: AppColors.emergencyColor),
                      const SizedBox(height: 6),
                      Text('Tap to open PDF'.tr, style: AppTextStyles.body),
                    ]),
                  )
                : ApiImage(d.file, height: 240, width: double.infinity, fit: BoxFit.cover, radius: BorderRadius.circular(14)),
          ),
          const SizedBox(height: 12),
          Text(d.title, style: AppTextStyles.title),
          const SizedBox(height: 6),
          Row(children: [StatusChip(d.status), const SizedBox(width: 8), if (d.isShared) StatusChip('UPCOMING', label: 'Shared'.tr)]),
          if (d.status == 'REJECTED' && (d.moderationNote ?? '').isNotEmpty)
            HVCardBox(
              margin: const EdgeInsets.only(top: 10),
              borderColor: AppColors.emergencyColor,
              child: InfoLine(Icons.info_outline, d.moderationNote!, color: AppColors.emergencyColor),
            ),
          HVCardBox(
            margin: const EdgeInsets.only(top: 12),
            child: Column(children: [
              KeyValueRow('Category'.tr, Fmt.enumLabel(d.category).tr),
              KeyValueRow('Document date'.tr, Fmt.date(d.documentDate)),
              KeyValueRow('Uploaded'.tr, Fmt.dateTime(d.createdAt)),
              KeyValueRow('For'.tr, d.forWhom == 'SELF' ? 'Myself'.tr : (d.familyMemberName ?? 'Family'.tr)),
              if (d.tags.isNotEmpty) KeyValueRow('Tags'.tr, d.tags.map((t) => '#$t').join(' ')),
              if (d.sizeLabel.isNotEmpty) KeyValueRow('Size'.tr, d.sizeLabel),
            ]),
          ),
          if (c.shareUrl.value != null)
            HVCardBox(
              margin: const EdgeInsets.only(top: 12),
              color: AppColors.bottomNavigationColor,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Share link'.tr, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                SelectableText(c.shareUrl.value!, style: AppTextStyles.body.copyWith(fontSize: 12)),
                if (c.shareExpires.value != null)
                  Text("${'Expires'.tr}: ${Fmt.dateTime(c.shareExpires.value)}",
                      style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(onPressed: c.copyShare, icon: const Icon(Icons.copy), label: Text('Copy'.tr)),
                ),
              ]),
            ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Open file'.tr,
            icon: Icons.open_in_new,
            onPressed: () => FileViewer.open(d.file, title: d.title, mimeType: d.fileType),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: d.isShared ? 'New share link'.tr : 'Share with a doctor'.tr,
            icon: Icons.link,
            outlined: true,
            loading: c.isWorking.value,
            onPressed: _share,
          ),
          if (d.isShared) ...[
            const SizedBox(height: 10),
            PrimaryButton(label: 'Stop sharing'.tr, outlined: true, color: AppColors.greyColor, onPressed: c.stopShare),
          ],
          const SizedBox(height: 10),
          PrimaryButton(label: 'Delete'.tr, outlined: true, color: AppColors.emergencyColor, onPressed: c.deleteDoc),
          const SizedBox(height: 24),
        ]);
      }),
    );
  }
}
