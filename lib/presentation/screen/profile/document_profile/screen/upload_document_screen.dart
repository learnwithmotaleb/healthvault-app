import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/document_profile_controller.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final tag = 'upload-${DateTime.now().microsecondsSinceEpoch}';
  late final DocumentUploadController c;
  final dateText = TextEditingController();

  @override
  void initState() {
    super.initState();
    c = Get.put(DocumentUploadController(), tag: tag);
  }

  @override
  void dispose() {
    dateText.dispose();
    Get.delete<DocumentUploadController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'Upload document'.tr),
      body: Form(
        key: c.formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Obx(() => Column(children: [
                ...c.files.map((f) => LocalFileTile(file: f, onRemove: () => c.files.remove(f))),
                if (c.files.length < 5)
                  InkWell(
                    onTap: c.addFiles,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.bottomNavigationColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.5)),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primaryColor),
                        const SizedBox(height: 6),
                        Text(c.files.isEmpty ? 'Add files (PDF / image)'.tr : 'Add more'.tr,
                            style: AppTextStyles.body.copyWith(color: AppColors.primaryColor)),
                        Text('Up to 5 files · max 10MB each'.tr,
                            style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
                      ]),
                    ),
                  ),
              ])),
          const SizedBox(height: 16),
          LabeledField(label: 'Title (optional)'.tr, controller: c.title, hint: 'Blood test March'),
          Text('Category'.tr, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500)),
          Obx(() => ChoiceBar(
                padding: const EdgeInsets.symmetric(vertical: 8),
                values: documentCategories,
                labels: documentCategories.map((e) => Fmt.enumLabel(e).tr).toList(),
                selected: c.category.value,
                onSelected: (v) => c.category.value = v,
              )),
          LabeledField(label: 'Tags (comma separated)'.tr, controller: c.tagsText, hint: 'blood, annual'),
          LabeledField(
            label: 'Document date'.tr,
            controller: dateText,
            readOnly: true,
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
            onTap: () async {
              final d = await Dialogs.pickDate(initial: c.documentDate.value, first: DateTime(1950), last: DateTime.now());
              if (d != null) {
                c.documentDate.value = d;
                dateText.text = Fmt.date(d);
              }
            },
          ),
          Obx(() => ChoiceBar(
                padding: const EdgeInsets.only(bottom: 8),
                values: const ['SELF', 'FAMILY'],
                labels: ['Myself'.tr, 'Family member'.tr],
                selected: c.forWhom.value,
                onSelected: (v) => c.forWhom.value = v,
              )),
          Obx(() => c.forWhom.value == 'FAMILY'
              ? LabeledField(label: 'Family member name'.tr, controller: c.familyName, validator: V.required)
              : const SizedBox.shrink()),
          const SizedBox(height: 16),
          Obx(() => PrimaryButton(label: 'Upload'.tr, loading: c.isSaving.value, onPressed: c.upload)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
