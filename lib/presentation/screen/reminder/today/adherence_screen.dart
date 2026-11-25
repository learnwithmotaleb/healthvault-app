import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/app_models.dart';
import '../../../../utils/app_colors/app_colors.dart';
import '../../../../utils/app_text_style/app_text_style.dart';
import '../../../widget/custom_appbar.dart';
import '../../../widget/hv_ui.dart';
import '../controller/reminder_controllers.dart';

class AdherenceScreen extends StatelessWidget {
  const AdherenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AdherenceController());
    final range = 30.obs;
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: 'Adherence'.tr),
      body: Obx(() {
        final s = c.summary.value;
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) c.loadMore();
            return false;
          },
          child: AsyncList(
            loading: c.isLoading.value,
            error: c.error.value,
            isEmpty: s == null,
            onRefresh: c.fetch,
            empty: EmptyView(title: 'No data yet'.tr),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                Obx(() => ChoiceBar(
                      padding: EdgeInsets.zero,
                      values: const ['7', '30', '90'],
                      labels: ['7 days'.tr, '30 days'.tr, '90 days'.tr],
                      selected: '${range.value}',
                      onSelected: (v) {
                        range.value = int.parse(v);
                        c.setRange(range.value);
                      },
                    )),
                const SizedBox(height: 8),
                if (s != null) _SummaryCard(s: s),
                if (c.byReminder.length > 1 || (c.byReminder.isNotEmpty && c.reminderId.value == null)) ...[
                  SectionTitle('By medicine'.tr),
                  ...c.byReminder.map((r) => HVCardBox(
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text("${r.pillName ?? ''} · ${r.dosage ?? ''}",
                                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text("✔ ${r.taken}   ✖ ${r.missed}   ⏭ ${r.skipped}   ⏳ ${r.pending}",
                                  style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                            ]),
                          ),
                          _rate(r.adherenceRate),
                        ]),
                      )),
                ],
                SectionTitle('History'.tr),
                if (c.history.isEmpty)
                  Text('No doses recorded in this period'.tr, style: AppTextStyles.body.copyWith(color: AppColors.hintColor)),
                ...c.history.map((h) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(
                        h.status == 'TAKEN'
                            ? Icons.check_circle
                            : h.status == 'MISSED'
                                ? Icons.cancel
                                : h.status == 'SKIPPED'
                                    ? Icons.skip_next
                                    : Icons.schedule,
                        color: statusColor(h.status),
                      ),
                      title: Text("${h.pillName ?? ''} ${h.dosage ?? ''}", style: AppTextStyles.body),
                      subtitle: Text(Fmt.dateTime(h.scheduledAt),
                          style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                      trailing: StatusChip(h.status),
                    )),
                if (c.isLoadingMore.value)
                  const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
              ],
            ),
          ),
        );
      }),
    );
  }

  static Widget _rate(num? r) => Text(
        r == null ? '–' : '${r.round()}%',
        style: AppTextStyles.title.copyWith(
          color: r == null ? AppColors.greyColor : (r >= 80 ? const Color(0xFF2E7D32) : (r >= 50 ? const Color(0xFFE09B00) : AppColors.emergencyColor)),
        ),
      );
}

class _SummaryCard extends StatelessWidget {
  final AdherenceStats s;
  const _SummaryCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final rate = s.adherenceRate;
    Widget stat(String label, int v, Color color) => Expanded(
          child: Column(children: [
            Text('$v', style: AppTextStyles.title.copyWith(color: color)),
            Text(label, style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
          ]),
        );
    return HVCardBox(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                value: rate == null ? 0 : rate / 100,
                strokeWidth: 8,
                backgroundColor: AppColors.bottomNavigationColor,
                color: AppColors.primaryColor,
              ),
              Center(child: Text(rate == null ? '–' : '${rate.round()}%', style: AppTextStyles.title)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              rate == null ? 'No confirmed doses yet'.tr : 'of your doses were taken on time'.tr,
              style: AppTextStyles.body,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          stat('Taken'.tr, s.taken, const Color(0xFF2E7D32)),
          stat('Missed'.tr, s.missed, AppColors.emergencyColor),
          stat('Skipped'.tr, s.skipped, AppColors.greyColor),
          stat('Pending'.tr, s.pending, const Color(0xFFE09B00)),
        ]),
      ]),
    );
  }
}
