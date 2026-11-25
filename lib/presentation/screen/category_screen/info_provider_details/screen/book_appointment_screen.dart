import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../helper/athens_time.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/info_provider_details_controller.dart';

/// Booking flow: service → date → time slot (Greek time) → reason.
class BookAppointmentScreen extends StatelessWidget {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<InfoProviderDetailsController>();
    final p = c.provider.value!;
    final todayAthens = AthensTime.now();
    final dates = List.generate(30, (i) => DateTime(todayAthens.year, todayAthens.month, todayAthens.day + i));

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'Book appointment'.tr),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: AppTextStyles.title.copyWith(fontSize: 17)),
            if (p.subtitle.isNotEmpty)
              Text(p.subtitle, style: AppTextStyles.body.copyWith(color: AppColors.primaryColor)),
            SectionTitle('1. ${'Select service'.tr}'),
            Obx(() => Column(
                  children: p.services.map((s) {
                    final sel = c.selectedService.value?.id == s.id;
                    return HVCardBox(
                      borderColor: sel ? AppColors.primaryColor : null,
                      color: sel ? AppColors.bottomNavigationColor : AppColors.whiteColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      onTap: () => c.selectedService.value = s,
                      child: Row(children: [
                        Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.title, style: AppTextStyles.body)),
                        Text(s.priceLabel,
                            style: AppTextStyles.body.copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }).toList(),
                )),
            SectionTitle('2. ${'Select date'.tr}'),
            SizedBox(
              height: 78,
              child: Obx(() {
                final selected = c.selectedDate.value;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final d = dates[i];
                    final enabled = c.isDateSelectable(d);
                    final isSel = selected != null && DateUtils.isSameDay(selected, d);
                    return GestureDetector(
                      onTap: enabled ? () => c.pickDate(d) : null,
                      child: Container(
                        width: 58,
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primaryColor
                              : (enabled ? AppColors.bottomNavigationColor : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: enabled ? AppColors.primaryColor.withValues(alpha: 0.4) : Colors.grey.shade300),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(Fmt.weekdayShort(d),
                              style: AppTextStyles.body.copyWith(
                                  fontSize: 12,
                                  color: isSel ? Colors.white : (enabled ? AppColors.primaryColor : Colors.grey))),
                          Text('${d.day}',
                              style: AppTextStyles.title.copyWith(
                                  fontSize: 18, color: isSel ? Colors.white : (enabled ? Colors.black : Colors.grey))),
                          Text(Fmt.monthShort(d),
                              style: AppTextStyles.body.copyWith(
                                  fontSize: 11, color: isSel ? Colors.white : (enabled ? AppColors.hintColor : Colors.grey))),
                        ]),
                      ),
                    );
                  },
                );
              }),
            ),
            SectionTitle('3. ${'Select time'.tr}'),
            Obx(() {
              final d = c.selectedDate.value;
              if (d == null) {
                return Text('Choose a date first'.tr, style: AppTextStyles.body.copyWith(color: AppColors.hintColor));
              }
              if (c.acceptsAnyTime) return _FreeTimePicker(c: c);
              final slots = c.slotsFor(d);
              if (slots.isEmpty) {
                return Text('No free times on this day'.tr,
                    style: AppTextStyles.body.copyWith(color: AppColors.emergencyColor));
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: slots.map((t) {
                    final sel = c.selectedSlot.value == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: sel,
                      showCheckmark: false,
                      selectedColor: AppColors.primaryColor,
                      labelStyle: TextStyle(color: sel ? Colors.white : AppColors.primaryColor),
                      side: const BorderSide(color: AppColors.primaryColor),
                      backgroundColor: Colors.white,
                      onSelected: (_) => c.selectedSlot.value = t,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text('Times are Greek time'.tr, style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
              ]);
            }),
            SectionTitle('4. ${'Reason for visit'.tr}'),
            LabeledField(
              label: '',
              controller: c.reasonController,
              hint: 'e.g. Chest pain when running'.tr,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Obx(() => PrimaryButton(
                  label: 'Confirm booking'.tr,
                  loading: c.isBooking.value,
                  onPressed: c.book,
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FreeTimePicker extends StatelessWidget {
  final InfoProviderDetailsController c;
  const _FreeTimePicker({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() => OutlinedButton.icon(
          onPressed: () async {
            final t = await Dialogs.pickTime(initial: const TimeOfDay(hour: 10, minute: 0));
            if (t != null) c.selectedSlot.value = AthensTime.hhmm(t.hour * 60 + t.minute);
          },
          icon: const Icon(Icons.access_time),
          label: Text(c.selectedSlot.value == null
              ? 'Pick a time (Greek time)'.tr
              : "${c.selectedSlot.value} (${'Greek time'.tr})"),
        ));
  }
}
