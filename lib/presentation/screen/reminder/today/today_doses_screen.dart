import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/route_path.dart';
import '../../../../utils/app_colors/app_colors.dart';
import '../../../../utils/app_text_style/app_text_style.dart';
import '../../../widget/custom_appbar.dart';
import '../../../widget/hv_ui.dart';
import '../controller/reminder_controllers.dart';
import '../widget/dose_tile.dart';

class TodayDosesScreen extends StatelessWidget {
  const TodayDosesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(TodayDosesController());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: "Today's doses".tr, actions: [
        IconButton(
          onPressed: () => Get.toNamed(RoutePath.adherence),
          icon: const Icon(Icons.insights_outlined, color: AppColors.primaryColor),
        ),
      ]),
      body: Obx(() {
        final taken = c.doses.where((d) => d.status == 'TAKEN').length;
        return AsyncList(
          loading: c.isLoading.value,
          error: c.error.value,
          isEmpty: c.doses.isEmpty,
          onRefresh: c.fetch,
          empty: EmptyView(
            icon: Icons.medication_outlined,
            title: 'Nothing scheduled today'.tr,
            action: OutlinedButton(onPressed: () => Get.toNamed(RoutePath.addReminder), child: Text('Add reminder'.tr)),
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              HVCardBox(
                color: AppColors.primaryColor,
                child: Row(children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(fit: StackFit.expand, children: [
                      CircularProgressIndicator(
                        value: c.doses.isEmpty ? 0 : taken / c.doses.length,
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                      Center(
                        child: Text("$taken/${c.doses.length}",
                            style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text('doses taken today'.tr,
                        style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 16)),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              ...c.doses.map((d) => DoseTile(
                    dose: d,
                    busy: c.busy.contains(d.reminderId + d.scheduledAt),
                    onRecord: (s) => c.record(d, s),
                  )),
              const SizedBox(height: 8),
              Text('Doses not confirmed within 2 hours are marked as missed.'.tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
            ],
          ),
        );
      }),
    );
  }
}
