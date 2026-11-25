import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/health_log_controller.dart';

class AddHealthLogScreen extends StatefulWidget {
  const AddHealthLogScreen({super.key});

  @override
  State<AddHealthLogScreen> createState() => _AddHealthLogScreenState();
}

class _AddHealthLogScreenState extends State<AddHealthLogScreen> {
  final tag = 'hlog-${DateTime.now().microsecondsSinceEpoch}';
  late final HealthLogFormController c;
  late final TextEditingController dateText;

  @override
  void initState() {
    super.initState();
    c = Get.put(HealthLogFormController(), tag: tag);
    dateText = TextEditingController(text: Fmt.dateTime(c.recordedAt.value));
  }

  @override
  void dispose() {
    dateText.dispose();
    Get.delete<HealthLogFormController>(tag: tag);
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final d = await Dialogs.pickDate(initial: c.recordedAt.value, first: DateTime(2000), last: DateTime.now());
    if (d == null) return;
    final t = await Dialogs.pickTime(initial: TimeOfDay.fromDateTime(c.recordedAt.value));
    final dt = DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
    c.recordedAt.value = dt;
    dateText.text = Fmt.dateTime(dt);
  }

  Widget _num(String label, TextEditingController ctl, String unit, num min, num max) => LabeledField(
        label: "$label ($unit)",
        controller: ctl,
        hint: "$min – $max",
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: V.numberIn(min, max),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: c.isEdit ? 'Edit health log'.tr : 'Add health log'.tr),
      body: Form(
        key: c.formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            LabeledField(
              label: 'Date & time'.tr,
              controller: dateText,
              readOnly: true,
              onTap: _pickDateTime,
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            Text('Blood pressure (mmHg)'.tr, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _num('Systolic'.tr, c.systolic, 'mmHg', 40, 300)),
              const SizedBox(width: 10),
              Expanded(child: _num('Diastolic'.tr, c.diastolic, 'mmHg', 20, 200)),
            ]),
            Row(children: [
              Expanded(child: _num('Heart rate'.tr, c.heartRate, 'bpm', 20, 300)),
              const SizedBox(width: 10),
              Expanded(child: _num('Weight'.tr, c.weight, 'kg', 0.5, 500)),
            ]),
            Row(children: [
              Expanded(child: _num('Blood sugar'.tr, c.bloodSugar, 'mg/dL', 10, 1000)),
              const SizedBox(width: 10),
              Expanded(child: _num('Temperature'.tr, c.temperature, '°C', 30, 45)),
            ]),
            _num('Oxygen saturation'.tr, c.oxygen, '%', 50, 100),
            LabeledField(label: 'Note'.tr, controller: c.note, maxLines: 3),
            const SizedBox(height: 12),
            Obx(() => PrimaryButton(label: 'Save'.tr, loading: c.isSaving.value, onPressed: c.save)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
