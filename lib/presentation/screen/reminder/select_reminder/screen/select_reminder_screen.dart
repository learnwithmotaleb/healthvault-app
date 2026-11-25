import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../data/models/app_models.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../../controller/reminder_controllers.dart';

/// Reminders tab – list, today's doses and adherence shortcuts.
class SelectReminderScreen extends StatelessWidget {
  const SelectReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<ReminderListController>()
        ? Get.find<ReminderListController>()
        : Get.put(ReminderListController());

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.reminder.tr, showBack: Navigator.of(context).canPop()),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        onPressed: () => Get.toNamed(RoutePath.addReminder),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add reminder'.tr, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Row(children: [
            Expanded(
              child: _Shortcut(
                icon: Icons.today_outlined,
                label: "Today's doses".tr,
                onTap: () => Get.toNamed(RoutePath.todayDoses),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Shortcut(
                icon: Icons.insights_outlined,
                label: 'Adherence'.tr,
                onTap: () => Get.toNamed(RoutePath.adherence),
              ),
            ),
          ]),
        ),
        Obx(() => ChoiceBar(
              values: const ['current', 'ended', 'all'],
              labels: ['Current'.tr, 'Ended'.tr, 'All'.tr],
              selected: c.filter.value,
              onSelected: c.setFilter,
            )),
        Expanded(
          child: Obx(() => AsyncList(
                loading: c.isLoading.value,
                error: c.error.value,
                isEmpty: c.reminders.isEmpty,
                onRefresh: c.fetch,
                empty: EmptyView(
                  icon: Icons.alarm_add_outlined,
                  title: 'No reminders'.tr,
                  subtitle: 'Add your medicines and get a push at each dose time.'.tr,
                ),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                  itemCount: c.reminders.length,
                  itemBuilder: (_, i) => _ReminderCard(r: c.reminders[i], c: c),
                ),
              )),
        ),
      ]),
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Shortcut({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HVCardBox(
      color: AppColors.bottomNavigationColor,
      borderColor: AppColors.primaryColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      onTap: onTap,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Flexible(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.primaryColor, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel r;
  final ReminderListController c;
  const _ReminderCard({required this.r, required this.c});

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    String scheduleText = r.schedule.tr;
    if (r.schedule == 'Weekly' && r.dayOfWeek != null) scheduleText += ' · ${_days[r.dayOfWeek! % 7].tr}';
    if (r.schedule == 'Monthly' && r.dayOfMonth != null) scheduleText += ' · ${'day'.tr} ${r.dayOfMonth}';

    return HVCardBox(
      onTap: () => Get.toNamed(RoutePath.editReminder, arguments: r),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.bottomNavigationColor, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.medication, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.pillName, style: AppTextStyles.title.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
              Text("${r.dosage} · $scheduleText", style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
            ]),
          ),
          if (!r.isActive) StatusChip('SKIPPED', label: 'Paused'.tr),
          if (r.isEnded) const SizedBox(width: 4),
          if (r.isEnded) StatusChip('CLOSED', label: 'Ended'.tr),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') Get.toNamed(RoutePath.editReminder, arguments: r);
              if (v == 'toggle') c.toggleActive(r);
              if (v == 'history') Get.toNamed(RoutePath.adherence, arguments: {"reminderId": r.id});
              if (v == 'delete') c.delete(r);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text('Edit'.tr)),
              PopupMenuItem(value: 'toggle', child: Text(r.isActive ? 'Pause'.tr : 'Resume'.tr)),
              PopupMenuItem(value: 'history', child: Text('History'.tr)),
              PopupMenuItem(value: 'delete', child: Text('Delete'.tr, style: const TextStyle(color: AppColors.emergencyColor))),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: r.times.map((t) => StatusChip('UPCOMING', label: t)).toList()),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: InfoLine(Icons.date_range, "${Fmt.date(r.startDate)} → ${Fmt.date(r.endDate)}")),
          if (r.assignedTo != 'SELF')
            Text("${'For'.tr}: ${r.assignedTo}", style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.primaryColor)),
        ]),
        if ((r.instructions ?? '').isNotEmpty) InfoLine(Icons.info_outline, r.instructions!),
        if ((r.prescriptionFile ?? '').isNotEmpty) InfoLine(Icons.attach_file, 'Prescription attached'.tr),
      ]),
    );
  }
}
