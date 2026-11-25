import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/routes/route_path.dart';
import '../../../../../service/socket_service.dart';
import '../../../../../utils/app_colors/app_colors.dart';
import '../../../../../utils/app_text_style/app_text_style.dart';
import '../../../../../utils/static_strings/static_strings.dart';
import '../../../../widget/hv_ui.dart';
import '../../../appointment/widget/appointment_tile.dart';
import '../../provider_bottom_nav/controller/provider_bottom_nav_controller.dart';
import '../controller/provider_home_controller.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<ProviderHomeController>() ? Get.find<ProviderHomeController>() : Get.put(ProviderHomeController());

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: RefreshIndicator(
        onRefresh: c.refresh,
        child: Obx(() {
          final p = c.profile;
          return ListView(padding: EdgeInsets.zero, children: [
            Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 20),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(children: [
                Avatar(image: p?.profileImage, name: c.fullName, radius: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.fullName.isEmpty ? AppStrings.welcomeBack.tr : c.fullName,
                        style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 17)),
                    Text(c.specialization.isNotEmpty ? c.specialization : AppStrings.welcomeBack.tr,
                        style: AppTextStyles.body.copyWith(color: Colors.white70)),
                  ]),
                ),
                Obx(() {
                  final n = RealtimeService.to.unreadCount.value;
                  return IconButton(
                    onPressed: () => Get.toNamed(RoutePath.notification),
                    icon: Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.notifications, color: Colors.white),
                    ),
                  );
                }),
              ]),
            ),
            if (p != null && !p.isApproved)
              HVCardBox(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                color: p.approvalStatus == 'REJECTED' ? const Color(0xFFFDECEA) : const Color(0xFFFFF6E0),
                borderColor: p.approvalStatus == 'REJECTED' ? AppColors.emergencyColor : const Color(0xFFE09B00),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(p.approvalStatus == 'REJECTED' ? Icons.block : Icons.hourglass_top,
                      color: p.approvalStatus == 'REJECTED' ? AppColors.emergencyColor : const Color(0xFFE09B00)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        p.approvalStatus == 'REJECTED' ? 'Your profile was not approved'.tr : 'Your profile is under review'.tr,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.approvalStatus == 'REJECTED'
                            ? (p.rejectionReason ?? 'Contact support for details.'.tr)
                            : "Patients can find and book you once an admin approves your account. We'll notify you.".tr,
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => Get.toNamed(RoutePath.supportChat),
                        child: Text('Contact support'.tr),
                      ),
                    ]),
                  ),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(children: [
                _stat('Requests'.tr, c.pendingCount.value, const Color(0xFFE09B00), () => _openTasks('PENDING')),
                const SizedBox(width: 8),
                _stat('Upcoming'.tr, c.upcomingCount.value, AppColors.primaryColor, () => _openTasks('upcoming')),
                const SizedBox(width: 8),
                _stat('Completed'.tr, c.completedCount.value, AppColors.loginLogoRadiusColor, () => _openTasks('COMPLETED')),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.toNamed(RoutePath.providerSchedule),
                    icon: const Icon(Icons.schedule),
                    label: Text('Availability'.tr),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.toNamed(RoutePath.providerService),
                    icon: const Icon(Icons.medical_services_outlined),
                    label: Text('Services'.tr),
                  ),
                ),
              ]),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: SectionTitle(AppStrings.appointmentRequest.tr)),
            if (c.isLoading.value && c.pending.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (c.pending.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('No new requests'.tr, style: AppTextStyles.body.copyWith(color: AppColors.hintColor)),
              )
            else
              ...c.pending.map((a) => AppointmentTile(
                    a: a,
                    showPatient: true,
                    onTap: () => Get.toNamed(RoutePath.appointmentDetails, arguments: {"id": a.id}),
                    trailing: c.busy.contains(a.id)
                        ? const LinearProgressIndicator()
                        : Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.emergencyColor),
                                onPressed: () async {
                                  final r = await Dialogs.input(title: 'Decline request'.tr, hint: 'Reason (optional)'.tr);
                                  if (r != null) c.setStatus(a, 'CANCELLED', reason: r);
                                },
                                child: Text('Decline'.tr),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColor),
                                onPressed: () => c.setStatus(a, 'CONFIRMED'),
                                child: Text('Confirm'.tr),
                              ),
                            ),
                          ]),
                  )),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: SectionTitle('Upcoming'.tr)),
            if (c.upcoming.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('No confirmed appointments'.tr, style: AppTextStyles.body.copyWith(color: AppColors.hintColor)),
              ),
            ...c.upcoming.map((a) => AppointmentTile(
                  a: a,
                  showPatient: true,
                  onTap: () => Get.toNamed(RoutePath.appointmentDetails, arguments: {"id": a.id}),
                )),
            const SizedBox(height: 24),
          ]);
        }),
      ),
    );
  }

  void _openTasks(String status) {
    if (Get.isRegistered<ProviderBottomNavController>()) {
      Get.find<ProviderBottomNavController>().openTasks(status);
    }
  }

  Widget _stat(String label, int value, Color color, VoidCallback onTap) => Expanded(
        child: HVCardBox(
          margin: EdgeInsets.zero,
          color: color.withValues(alpha: 0.08),
          borderColor: color.withValues(alpha: 0.5),
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Text('$value', style: AppTextStyles.title.copyWith(color: color, fontSize: 22)),
            Text(label, style: AppTextStyles.body.copyWith(color: color, fontSize: 12)),
          ]),
        ),
      );
}
