import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../../../../widget/file_viewer.dart';
import '../../controller/reminder_controllers.dart';

/// Create (no arguments) or edit (arguments: ReminderModel) a reminder.
class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({super.key});

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  late final ReminderFormController c;
  final tag = 'reminder-form-${DateTime.now().microsecondsSinceEpoch}';
  late final TextEditingController startText;
  late final TextEditingController endText;

  static const _weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    c = Get.put(ReminderFormController(), tag: tag);
    startText = TextEditingController(text: Fmt.date(c.startDate.value));
    endText = TextEditingController(text: Fmt.date(c.endDate.value));
  }

  @override
  void dispose() {
    startText.dispose();
    endText.dispose();
    Get.delete<ReminderFormController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: c.isEdit ? 'Edit reminder'.tr : 'Add reminder'.tr),
      body: Form(
        key: c.formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LabeledField(label: 'Medicine name'.tr, controller: c.pillName, hint: 'Aspirin', validator: V.required),
            LabeledField(label: 'Dosage'.tr, controller: c.dosage, hint: '100mg / 1 tablet', validator: V.required),
            Text('Schedule'.tr, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500)),
            Obx(() => ChoiceBar(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  values: const ['Daily', 'Weekly', 'Monthly'],
                  labels: ['Daily'.tr, 'Weekly'.tr, 'Monthly'.tr],
                  selected: c.schedule.value,
                  onSelected: (v) => c.schedule.value = v,
                )),
            Obx(() {
              if (c.schedule.value == 'Weekly') {
                return LabeledDropdown<int>(
                  label: 'Day of week'.tr,
                  value: c.dayOfWeek.value,
                  items: List.generate(7, (i) => i),
                  itemLabel: (i) => _weekdays[i].tr,
                  onChanged: (v) => c.dayOfWeek.value = v ?? 1,
                );
              }
              if (c.schedule.value == 'Monthly') {
                return LabeledDropdown<int>(
                  label: 'Day of month'.tr,
                  value: c.dayOfMonth.value,
                  items: List.generate(31, (i) => i + 1),
                  itemLabel: (i) => '$i',
                  onChanged: (v) => c.dayOfMonth.value = v ?? 1,
                );
              }
              return const SizedBox.shrink();
            }),
            Row(children: [
              Expanded(child: Text('Times (Greek time)'.tr, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500))),
              TextButton.icon(onPressed: c.addTime, icon: const Icon(Icons.add_alarm), label: Text('Add time'.tr)),
            ]),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: c.times
                      .map((t) => InputChip(
                            label: Text(t),
                            backgroundColor: AppColors.bottomNavigationColor,
                            side: const BorderSide(color: AppColors.primaryColor),
                            onDeleted: () => c.times.remove(t),
                          ))
                      .toList(),
                )),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: LabeledField(
                  label: 'Start date'.tr,
                  controller: startText,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final d = await Dialogs.pickDate(initial: c.startDate.value, first: DateTime(2020));
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
                  label: 'End date'.tr,
                  controller: endText,
                  readOnly: true,
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final d = await Dialogs.pickDate(
                        initial: c.endDate.value ?? c.startDate.value, first: c.startDate.value ?? DateTime(2020));
                    if (d != null) {
                      c.endDate.value = d;
                      endText.text = Fmt.date(d);
                    }
                  },
                ),
              ),
            ]),
            LabeledField(label: 'Instructions'.tr, controller: c.instructions, hint: 'After food'.tr, maxLines: 2),
            Obx(() => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primaryColor,
                  title: Text('For a family member'.tr, style: AppTextStyles.body),
                  value: c.forFamily.value,
                  onChanged: (v) => c.forFamily.value = v,
                )),
            Obx(() => c.forFamily.value
                ? LabeledField(label: 'Family member name'.tr, controller: c.familyName, validator: V.required)
                : const SizedBox.shrink()),
            if (c.isEdit)
              Obx(() => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.primaryColor,
                    title: Text('Active'.tr, style: AppTextStyles.body),
                    value: c.isActive.value,
                    onChanged: (v) => c.isActive.value = v,
                  )),
            Text('Prescription (optional)'.tr, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Obx(() {
              if (c.prescription.value != null) {
                return LocalFileTile(file: c.prescription.value!, onRemove: () => c.prescription.value = null);
              }
              return Row(children: [
                OutlinedButton.icon(
                  onPressed: c.pickPrescription,
                  icon: const Icon(Icons.upload_file),
                  label: Text((c.existingPrescription.value ?? '').isEmpty ? 'Attach file'.tr : 'Replace file'.tr),
                ),
                if ((c.existingPrescription.value ?? '').isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => FileViewer.open(c.existingPrescription.value!, title: 'Prescription'.tr),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text('View'.tr),
                  ),
                ],
              ]);
            }),
            const SizedBox(height: 24),
            Obx(() => PrimaryButton(
                  label: c.isEdit ? 'Save changes'.tr : 'Create reminder'.tr,
                  loading: c.isSaving.value,
                  onPressed: c.save,
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
