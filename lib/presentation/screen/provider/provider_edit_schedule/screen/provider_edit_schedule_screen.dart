import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../data/models/user_models.dart';
import '../../../../../helper/athens_time.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/provider_edit_schedule_controller.dart';

class ProviderEditScheduleScreen extends StatelessWidget {
  const ProviderEditScheduleScreen({super.key});

  static const _names = {
    'MON': 'Monday',
    'TUE': 'Tuesday',
    'WED': 'Wednesday',
    'THU': 'Thursday',
    'FRI': 'Friday',
    'SAT': 'Saturday',
    'SUN': 'Sunday',
  };

  Future<void> _addSlot(ProviderEditScheduleController c, String day) async {
    final start = await Dialogs.pickTime(initial: const TimeOfDay(hour: 9, minute: 0));
    if (start == null) return;
    final end = await Dialogs.pickTime(initial: TimeOfDay(hour: (start.hour + 4).clamp(0, 23), minute: start.minute));
    if (end == null) return;
    c.addSlot(day, AthensTime.hhmm(start.hour * 60 + start.minute), AthensTime.hhmm(end.hour * 60 + end.minute));
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProviderEditScheduleController());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'Weekly availability'.tr),
      body: Obx(() {
        if (c.isLoading.value && c.days.isEmpty) return const Center(child: CircularProgressIndicator());
        if (c.error.value != null && c.days.isEmpty) return ErrorView(message: c.error.value!, onRetry: c.fetch);
        final noSlots = c.days.every((d) => d.slots.isEmpty);
        return RefreshIndicator(
          onRefresh: c.fetch,
          child: ListView(padding: const EdgeInsets.all(12), children: [
            HVCardBox(
              color: AppColors.bottomNavigationColor,
              child: InfoLine(
                Icons.info_outline,
                noSlots
                    ? 'No availability set – patients can book any time. Add time slots to limit bookings.'.tr
                    : 'Patients can only book inside these slots. Times are Greek time.'.tr,
              ),
            ),
            if (c.isSaving.value) const LinearProgressIndicator(),
            ...AvailabilityDay.order.map((key) {
              final d = c.dayFor(key);
              return HVCardBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(_names[key]!.tr, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    if (d != null)
                      IconButton(
                        tooltip: 'Remove day'.tr,
                        onPressed: () => c.deleteDay(d),
                        icon: const Icon(Icons.delete_outline, color: AppColors.emergencyColor, size: 20),
                      ),
                    TextButton.icon(
                      onPressed: c.isSaving.value ? null : () => _addSlot(c, key),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('Slot'.tr),
                    ),
                  ]),
                  if (d == null || d.slots.isEmpty)
                    Text('Not available'.tr, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: d.slots
                          .map((s) => InputChip(
                                label: Text("${s.startTime} – ${s.endTime}"),
                                backgroundColor: AppColors.bottomNavigationColor,
                                side: const BorderSide(color: AppColors.primaryColor),
                                onDeleted: () => c.deleteSlot(s),
                              ))
                          .toList(),
                    ),
                ]),
              );
            }),
          ]),
        );
      }),
    );
  }
}
