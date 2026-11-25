import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../data/models/app_models.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/custom_appbar.dart';
import '../../../../widget/file_viewer.dart';
import '../../../../widget/hv_ui.dart';
import '../controller/insurancce_controller.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(InsuranceController());
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.insurance.tr),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () => Get.toNamed(RoutePath.addInsurance, arguments: {"forWhom": c.forWhom.value}),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(children: [
        Obx(() => ChoiceBar(
              values: const ['ALL', 'SELF', 'FAMILY'],
              labels: ['All'.tr, 'Myself'.tr, 'Family'.tr],
              selected: c.forWhom.value,
              onSelected: c.setForWhom,
            )),
        Expanded(
          child: Obx(() => AsyncList(
                loading: c.isLoading.value,
                error: c.error.value,
                isEmpty: c.items.isEmpty,
                onRefresh: c.fetch,
                empty: EmptyView(
                  icon: Icons.shield_outlined,
                  title: 'No insurance added'.tr,
                  subtitle: "We'll remind you 30, 7 and 1 day before it expires.".tr,
                ),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                  itemCount: c.items.length,
                  itemBuilder: (_, i) => _InsuranceCard(i: c.items[i], c: c),
                ),
              )),
        ),
      ]),
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  final InsuranceModel i;
  final InsuranceController c;
  const _InsuranceCard({required this.i, required this.c});

  @override
  Widget build(BuildContext context) {
    final days = i.daysToExpiry;
    final (String status, String label) = i.isExpired
        ? ('CANCELLED', 'Expired'.tr)
        : (days != null && days <= 30)
            ? ('PENDING', '${'Expires in'.tr} $days ${'days'.tr}')
            : ('CONFIRMED', 'Active'.tr);
    return HVCardBox(
      padding: EdgeInsets.zero,
      onTap: () => Get.toNamed(RoutePath.addInsurance, arguments: {"insurance": i}),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            gradient: LinearGradient(colors: [AppColors.primaryColor, AppColors.providerHomePageColor]),
          ),
          child: Row(children: [
            const Icon(Icons.shield, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.name, style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 16)),
                Text(i.insuranceProvider, style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 11, color: statusColor(status))),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                KeyValueRow('Policy number'.tr, i.number),
                KeyValueRow('Expiry date'.tr, Fmt.date(i.expiryDate)),
                if ((i.coverageType ?? '').isNotEmpty) KeyValueRow('Coverage'.tr, i.coverageType!),
                KeyValueRow('For'.tr, i.forWhom == 'SELF' ? 'Myself'.tr : (i.familyMemberName ?? 'Family'.tr)),
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') Get.toNamed(RoutePath.addInsurance, arguments: {"insurance": i});
                if (v == 'photo') FileViewer.open(i.photo!, title: i.name);
                if (v == 'delete') c.delete(i);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text('Edit'.tr)),
                if ((i.photo ?? '').isNotEmpty) PopupMenuItem(value: 'photo', child: Text('View card'.tr)),
                PopupMenuItem(value: 'delete', child: Text('Delete'.tr, style: const TextStyle(color: AppColors.emergencyColor))),
              ],
            ),
          ]),
        ),
      ]),
    );
  }
}
