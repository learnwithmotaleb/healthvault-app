import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/file_viewer.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/insurancce_controller.dart';

class AddInsuranceScreen extends StatefulWidget {
  const AddInsuranceScreen({super.key});

  @override
  State<AddInsuranceScreen> createState() => _AddInsuranceScreenState();
}

class _AddInsuranceScreenState extends State<AddInsuranceScreen> {
  final tag = 'ins-${DateTime.now().microsecondsSinceEpoch}';
  late final InsuranceFormController c;
  late final TextEditingController startText;
  late final TextEditingController expiryText;

  @override
  void initState() {
    super.initState();
    c = Get.put(InsuranceFormController(), tag: tag);
    startText = TextEditingController(text: c.startDate.value == null ? '' : Fmt.date(c.startDate.value));
    expiryText = TextEditingController(text: c.expiryDate.value == null ? '' : Fmt.date(c.expiryDate.value));
  }

  @override
  void dispose() {
    startText.dispose();
    expiryText.dispose();
    Get.delete<InsuranceFormController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: c.isEdit ? 'Edit insurance'.tr : 'Add insurance'.tr),
      body: Form(
        key: c.formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
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
          LabeledField(label: 'Plan name'.tr, controller: c.name, hint: 'Family health plan', validator: V.required),
          LabeledField(label: 'Policy number'.tr, controller: c.number, hint: 'POL-778899', validator: V.required),
          LabeledField(label: 'Insurance company'.tr, controller: c.provider, hint: 'Interamerican', validator: V.required),
          LabeledField(label: 'Coverage type'.tr, controller: c.coverage, hint: 'Hospital'),
          Row(children: [
            Expanded(
              child: LabeledField(
                label: 'Start date'.tr,
                controller: startText,
                readOnly: true,
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final d = await Dialogs.pickDate(initial: c.startDate.value, first: DateTime(2000));
                  if (d != null) {
                    c.startDate.value = d;
                    startText.text = Fmt.date(d);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LabeledField(
                label: 'Expiry date'.tr,
                controller: expiryText,
                readOnly: true,
                validator: V.required,
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final d = await Dialogs.pickDate(initial: c.expiryDate.value, first: DateTime(2000));
                  if (d != null) {
                    c.expiryDate.value = d;
                    expiryText.text = Fmt.date(d);
                  }
                },
              ),
            ),
          ]),
          Obx(() => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primaryColor,
                title: Text('Expiry reminders'.tr, style: AppTextStyles.body),
                subtitle: Text('30, 7 and 1 day before, at 09:00'.tr, style: AppTextStyles.body.copyWith(fontSize: 12)),
                value: c.reminderEnabled.value,
                onChanged: (v) => c.reminderEnabled.value = v,
              )),
          Text('Insurance card photo'.tr, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Obx(() {
            if (c.photo.value != null) {
              return LocalFileTile(file: c.photo.value!, onRemove: () => c.photo.value = null);
            }
            final existing = c.existingPhoto.value;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if ((existing ?? '').isNotEmpty && !existing!.toLowerCase().endsWith('.pdf'))
                GestureDetector(
                  onTap: () => FileViewer.open(existing),
                  child: ApiImage(existing, height: 160, width: double.infinity, radius: BorderRadius.circular(10)),
                ),
              if ((existing ?? '').isNotEmpty && existing!.toLowerCase().endsWith('.pdf'))
                TextButton.icon(
                  onPressed: () => FileViewer.open(existing),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text('View current file'.tr),
                ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: c.pickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text((existing ?? '').isEmpty ? 'Add photo / PDF'.tr : 'Replace'.tr),
              ),
            ]);
          }),
          const SizedBox(height: 24),
          Obx(() => PrimaryButton(label: 'Save'.tr, loading: c.isSaving.value, onPressed: c.save)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
