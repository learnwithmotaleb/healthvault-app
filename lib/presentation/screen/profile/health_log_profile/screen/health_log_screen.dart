import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../data/models/app_models.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/health_log_controller.dart';

class HealthLogScreen extends StatelessWidget {
  const HealthLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HealthLogController());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.healthLogs.tr, actions: [
        IconButton(
          tooltip: 'Trends'.tr,
          onPressed: () => Get.toNamed(RoutePath.healthTrends, arguments: {"forWhom": c.forWhom.value}),
          icon: const Icon(Icons.show_chart, color: AppColors.primaryColor),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () => Get.toNamed(RoutePath.addHealthLog, arguments: {"forWhom": c.forWhom.value}),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(children: [
        Obx(() => ChoiceBar(
              values: const ['SELF', 'FAMILY'],
              labels: ['Myself'.tr, 'Family'.tr],
              selected: c.forWhom.value,
              onSelected: c.setForWhom,
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
                  isEmpty: c.logs.isEmpty,
                  onRefresh: c.fetch,
                  empty: EmptyView(
                    icon: Icons.monitor_heart_outlined,
                    title: 'No health logs yet'.tr,
                    subtitle: 'Track blood pressure, heart rate, weight, sugar and more.'.tr,
                  ),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: c.logs.length,
                    itemBuilder: (_, i) => _LogCard(log: c.logs[i], c: c),
                  ),
                ),
              )),
        ),
      ]),
    );
  }
}

class _LogCard extends StatelessWidget {
  final HealthLogModel log;
  final HealthLogController c;
  const _LogCard({required this.log, required this.c});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, String)>[
      if (log.bloodPressure != null) ('Blood pressure'.tr, log.bloodPressure!, 'mmHg'),
      if (log.heartRate != null) ('Heart rate'.tr, HealthLogModel.fmt(log.heartRate), 'bpm'),
      if (log.weight != null) ('Weight'.tr, HealthLogModel.fmt(log.weight), 'kg'),
      if (log.bloodSugar != null) ('Blood sugar'.tr, HealthLogModel.fmt(log.bloodSugar), 'mg/dL'),
      if (log.temperature != null) ('Temperature'.tr, HealthLogModel.fmt(log.temperature), '°C'),
      if (log.oxygenSaturation != null) ('Oxygen'.tr, HealthLogModel.fmt(log.oxygenSaturation), '%'),
    ];
    return HVCardBox(
      onTap: () => Get.toNamed(RoutePath.addHealthLog, arguments: {"log": log}),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.event_note, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              Fmt.dateTime(log.recordedAt) + (log.forWhom == 'FAMILY' ? '  ·  ${log.familyMemberName ?? ''}' : ''),
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          InkWell(
            onTap: () => c.delete(log),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline, color: AppColors.emergencyColor, size: 20),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: items
              .map((e) => Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.bottomNavigationColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(e.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(fontSize: 10, color: AppColors.hintColor)),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: e.$2, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                        TextSpan(text: ' ${e.$3}', style: AppTextStyles.body.copyWith(fontSize: 10)),
                      ])),
                    ]),
                  ))
              .toList(),
        ),
        if ((log.note ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(log.note!, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
        ],
      ]),
    );
  }
}
